# Berlin

**TODO: Add description**

# Deploying to Heroku

1. Install the Heroku CLI ([Heroku-CLI](https://devcenter.heroku.com/articles/heroku-cli))
2. Create a new Heroku project
    1. Login to Heroku: `heroku login` (Don't use sudo or it will not work!)
    2. Create the project: `heroku create [app_name]`
3. Login to Heroku container: `sudo heroku container:login` (It's important that you have docker installed before executing this command.)
4. Build the docker container and upload it to heroku: `sudo heroku container:push web -a app_name`
5. Release the docker container: `sudo docker container:realease web -a app_name`

Your project url is now `app_name.herokuapp.com`. (Or the auto-generated one when you haven't supplied an app name.)
