# Telegram bot providing prices from binance api
![ezgif com-gif-maker (1)](https://user-images.githubusercontent.com/7008236/184308258-11cca399-0a4d-4d6e-a118-143b9778bb93.gif)

### This is not a production ready project!
#### This is an experiment for learning and testing purposes. 

## Postgres prerequisites

Application uses Postgres db for persistence.

One of the simplest ways to launch postgres locally is using the docker image:
```
docker run -p 5432:5432 --name XXX_NAME -e POSTGRES_PASSWORD=XXX_PWD -e POSTGRES_USER=XXX_USER -e POSTGRES_DB=XXX_DB -d postgres
```

Connection string must be properly updated within `/src/Db/Query.hs`


## Telegram bot prerequisites

Application requires telegram bot access token. 
You can register your bot and get its access token from BotFather `https://t.me/BotFather`

Access token must be properly updated within `/src/TelegramBot.hs`
