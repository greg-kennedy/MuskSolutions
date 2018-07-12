#!/usr/bin/env perl
use strict;
use warnings;

# proper Unicode and JSON::PP
use v5.014;

###
# A Twitter bot to generate fake Elon Musk tech solutions

# fudge @INC
use FindBin qw( $RealBin );
use lib $RealBin;

# Includes
# Decode JSON (config file, word banks)
use JSON::PP qw( decode_json );

# LWP::UserAgent (connect to remote URLs)
use LWP::UserAgent;

# Time::Piece to transform date/time returned by API calls to something we understand
use Time::Piece;

# Twitter posting
use Net::Twitter::Lite::WithAPIv1_1;
use Util;

# Determining "blessed" status of objects
use Scalar::Util 'blessed';

###############################################################
### CODE
###############################################################

###############################################################
# Helper functions

# chooses a random element from an array
sub pick { return $_[int(rand(@_))]; }

sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

# Decode JSON from a file (instead of a scalar)
sub decode_json_file
{
  my $filename = shift;

  decode_json do {
    #open(my $json_fh, "<:encoding(UTF-8)", $filename)
    open(my $json_fh, "<", $filename)
      or die("Can't open $filename: $!\n");

    local $/;
    <$json_fh>;
  }
}

# Query Twitter for the top stories
#  Returns a reference to a list of hashes, containing title, description, and date published
sub query_twitter
{
  my $nt = shift;

  # Get twitter trends for USA, excluding hashtags
  my $trends = $nt->trends( { id => 23424977, exclude => 'hashtags' } );

  # Pack Trends into news array
  my @news;

  foreach my $trend (@{$trends->[0]{trends}}) {
    push @news, {
      title => $trend->{name},
      date => $trends->[0]{created_at}
    }
  }

  return \@news;
}

# Query newsapi.org for the top stories
#  Returns a reference to a list of hashes, containing title, description, and date published
=pod
sub query_newsapi
{
  my $config = shift;

  # construct request URL incl. API key
  #  go ahead and get 100 items, "general" category, US country
  my $url = 'https://newsapi.org/v2/top-headlines?sources=cnn,cnbc,the-washington-post&pageSize=100&apiKey=' . $config->{newsapi_key};

  # Create a LWP::UserAgent and "get" the URL
  my $ua = LWP::UserAgent->new;
  my $response = $ua->get( $url );

  # Didn't get 200 status, die  
  if (! $response->is_success) {
    die $response->status_line;
  }

  # decode the JSON response.
  #  reformat into a "standard" hash structure, so the news parser can work cross-platform
  my $content = decode_json $response->decoded_content;

  my @news;
  foreach my $article (@{$content->{articles}})
  {
    # use strptime to convert this into something we understand
    push @news, {
      title => $article->{title},
      description => $article->{description},
      date => $article->{publishedAt},
    }
  }
  return \@news;
}
=cut

=pod
# Analyze the news headlines.  See if there's anything interesting to talk about.
my $topic;
my $weight;

foreach my $article (@$news) {
  
  # Look at the title for something to post about
  #  try splitting on conjunctions
  my @clauses = split /(?:,|;|\||\-|\s(?:and|but|for|nor|or|so|yet))\s/i, " $article->{title} ";

  foreach my $clause (@clauses)
  {
    # split clause on preposition into phrase
    my @phrases = split /\s(?:about|below|excepting|off|toward|above|beneath|for|on|under|across|beside|besides|from|onto|underneath|after|between|in|out|until|against|beyond|in front of|outside|up|along|but|inside|over|upon|among|by|in spite of|past|up to|around|concerning|instead of|regarding|with|at|despite|into|since|within|because of|down|like|through|without|before|during|near|throughout|with regard to|behind|except|of|to|with respect to)\s/i, " $clause ";
    foreach my $phrase (@phrases)
    {
      # for now "weight" is just the longest clause
      my $phrase_length = split /\s+/, $phrase;
      if ($phrase_length > $weight) {
        $weight = $phrase_length;
        $topic = trim($phrase);
      }
    }
  }
}
=cut

###############################################################
# MAIN ENTRY POINT

# Go read the config file
my $config = decode_json_file "$RealBin/config.json";


# Go read the data files
my $data = decode_json_file "$RealBin/data.json";

# Connect to Twitter
my $nt = Net::Twitter::Lite::WithAPIv1_1->new(
  consumer_key        => $config->{consumer_key},
  consumer_secret     => $config->{consumer_secret},
  access_token        => $config->{access_token},
  access_token_secret => $config->{access_token_secret},
  ssl                 => 1
);

# Get the latest trends
# Connect to news API
#  this calls a function accepting config, so you can replace with your own preferred news source
#my $news = query_newsapi($config);

# Retrieve Twitter trends instead
#  this is an alternative to newsapi
my $news = query_twitter($nt);

# choose a random thing to tweet about
my $topic = pick(@$news)->{title};

# Make a stupid device
my $idea = join(' ',
  pick("", uc(pick(@{$data->{adjectives}}))),
  uc(pick(@{$data->{adjectives}})),
  uc(pick(@{$data->{nouns}})),
  pick('using','incorporating','with','including','built with','made of','built on'),
  uc(pick(@{$data->{technologies}}))
);

# Compose tweet.
my $post = pick("Today in the news:", "Everybody's talking about", "I was thinking about", "A fan asked me about","Been thinking a lot about","Trying to come up with a way to help with","Re: situation regarding","Lots of people upset about", "Thinking of","Reflecting on") .
  ' ' . $topic .
  '. ' . pick("Real bummer.","Tough situation.","Difficult times.","That's a hard one.","") . " " .
  pick("I have a solution -", "This could be solved with", "I'm putting my people to work on", "We can fix this with", "I plan to use","I know what we need now -","I have it covered:","Don't worry, I got this:","Just brainstorming here, but what about","Consider:","How about trying to fix this using","Six words:","The solution is obvious.","Check this out -","Just got off the phone with my lead engineer, who is hard at work on") .
  ' ' . pick("a","my","the","") .
  ' ' . $idea .
  pick('!','.') .
  ' ' . pick('',pick("I'm",'So','Totally','Super','Really') .
  ' ' . pick('stoked','pumped','excited','ready','great') .
  pick('!','.'));

$post =~ s/\s+/ /g;

say $post;

# Get my timeline.  This is just to see the replies back since I last posted.
#my $status = $nt->mentions({ count => 1, trim_user => 1, exclude_replies => 1, include_rts => 0 })->[0];

###
# READY TO POST!!
# Post!
$nt->update( {status => $post} );
