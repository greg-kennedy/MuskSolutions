# MuskSolutions
Source code for the [@MuskSolutions](https://twitter.com/MuskSolutions) Twitter bot

## Background
In late June of 2018, a dozen boys and their soccer coach in Thailand became [trapped in a cave](https://en.wikipedia.org/wiki/Tham_Luang_cave_rescue) when heavy rains flooded the entrance while they were inside.  This event and the subsequent rescue attempts became an international sensation.  On July 7th, noted Twitter idiot Elon Musk decided he'd step in and save the day by building a miniature "submarine" for rescue divers to transport the children to safety.

The submarine was widely ridiculed as a prime example of Silicon Valley savior complex: a metal tube with pointless amenities ("padded wall pockets for a hand radio & phone/music player"), technologically sophisticated ("using the liquid oxygen transfer tube of Falcon rocket as hull"), yet completely unsuitable to actually solving the problem.  The Thai divers rejected it as a useless object and managed to rescue all thirteen trapped using traditional rescue methods.

Musk, for his part, brought the submarine to Thailand and dumped it there "in case it may be useful in the future".  His stunt attracted the ire of the Thai rescue chief, who commented that the submarine was not "practical", to which Musk attempted to defend his dignity - culminating in him [calling one of the British rescue drivers "pedo guy"](https://www.vox.com/2018/7/18/17576302/elon-musk-thai-cave-rescue-submarine).  No good deed...

## Bot
Inspired by these events, this is a Twitter bot that proposes technological solutions to trending topics.  On launch, it connects to Twitter, and retrieves the latest USA topics.  From there it selects one at random, and then creates some buzzword-filled solution using [corpora](https://github.com/dariusk/corpora).

Interaction with Twitter is handled with Net::Twitter::Lite.  This is now deprecated, and Twitter::API is recommended instead.

An earlier version of this would query NewsAPI to get headlines for major events.  This turned out to be difficult to parse, and less interesting than the trends.  Code to query NewsAPI is still in the source but is commented out.

So far the bot has been suspended once.
