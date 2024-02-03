# VoteServer

Setup script for Ubuntu 20.04 which installs Docker and Docker-compose and continues to run the server.

`wget -O - https://raw.githubusercontent.com/TheHarcker/VoteServer/main/prepare%20docker.sh | bash`
>**Known issue:**
>The script may need to run twice to finish


# Configuration
For additional configuration, the following environment variables can be set. The default configuration (And available keys) is:  
**`.env`**
> maxNameLength=100  
> joinPhraseLength=6  
> maxChatLength=1000  
> chatQueryLimit=100  
> chatRateLimitingSeconds=10.0  
> chatRateLimitingMessages=10  
> defaultValueForUnverifiedConstituents=false  
> enableChat=true  
> adminProfilePicture="/img/icon.png" 
 
 ## Docker compose: 
 Add the values above to an `.env`-file in the same directory as `docker-compose.yml`. (Or rather the directory from which `docker-compose up` is called)

Furthermore for Letsencrypt support (HTTPS), add the following keys to your `.env`-file, here expressed as the default for [vote.smkid.dk](vote.smkid.dk):
> VIRTUAL_HOST="vote.smkid.dk"  
> LETSENCRYPT_HOST="vote.smkid.dk"  
> LETSENCRYPT_EMAIL="admin@smkid.dk"   

## Related projects
This project includes 3 first party Swift packages: 
- [VoteKit](https://github.com/TheHarcker/VoteKit) 
>Definitions and counting of simple vote types
- [AltVoteKit](https://github.com/TheHarcker/AltVoteKit) 
>Definitions and counting of votes using the Alternative Vote  
- [VoteExchangeFormat](https://github.com/TheHarcker/VoteExchangeFormat)
> API object definitions, used by the iOS client

