About this container
---
This container runs a Plex media server instance. More about Plex can be found at:

  https://plex.tv


Building the container
---
Before building, there are a number of environment variables to ensure are correct
for your setup. Have a look through the `vars` file and update at will.

With those configured correctly for your setup, you can build the Docker container
by running the `build.sh` script.

```
$ ./build.sh
```


Running the container
---
It's really straight forward to run the Docker container. Just kick off the `run.sh`
script.

```
$ ./run.sh
```


Updating Plex
---
This container is now semi-auto updating!  Every time the container is started it will check to see that the latest build is installed.  To enable this feature PLEX_SERVER_VERSION needs to be defined within `vars` as either 'public' or 'plexpass' with appropriate creds

```
PLEX_SERVER_VERSION=public
```
OR
```
PLEX_SERVER_VERSION=plexpass
PLEXPASS_USER="username"
PLEXPASS_PASS="password"
```
Now go ahead and restart the container, plex will be running the latest build.
```
$ docker restart plex
```


Test the container
---
You should be able to connect to the plex server just like normal, but here is a
quick test you can run to make sure it's listening:

```
$ curl -I http://localhost:32400/web/index.html
HTTP/1.1 200 OK
Cache-Control: no-cache
Accept-Ranges: bytes
Connection: Keep-Alive
Keep-Alive: timeout=20
Content-Length: 2502
Content-Type: text/html
X-Plex-Protocol: 1.0
```
