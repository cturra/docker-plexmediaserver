About this container
---
This container runs a Plex media server instance. More about Plex can be found at:

  https://plex.tv


Building the container
---
Before building, there are a couple environment variables to ensure are correct
for your setup. In the `Dockerfile`, check:

* PLEX_ARCH - architecture (amd64 or i386)
* PLEX_SERVER_VERSION - version of plex that will be fetched

With those configured correctly for your setup, the following Docker build
command will create the container image:

```
$ docker build -t cturra/plex .
```


Running the container
---
The following example Docker run command mounts three volumes: two for media
(movies and tv shows) and one for the plex data directory. 

Additionally, I limits the number of cpu cores to 3 (cores 0-2) so that during
transcoding tasks it doesn't spike all cores on your machine. You will want to
adjust that according to the number of cpu cores your Docker host has.

```
$ docker run --name=plex --net=host --cpuset-cpus="0-2" \
  -v /media/movies:/movies:ro -v /media/tv:/tv:ro \
  -v /data/plex:/plex:rw -p 32400:32400 -d cturra/plex
```


Test the container
---
You should be able to connect to the plex server just like normal, but here is a
quick test you can run to make sure it's listening:

```
$ curl -IL http://localhost:32400/web
HTTP/1.1 301 Moved Permanently
Location: http://home.turra.ca:32400/web/index.html
Cache-Control: public
Content-Length: 0
Connection: Keep-Alive
Keep-Alive: timeout=20
X-Plex-Protocol: 1.0

HTTP/1.1 200 OK
Cache-Control: no-cache
Accept-Ranges: bytes
Connection: Keep-Alive
Keep-Alive: timeout=20
Content-Length: 2502
Content-Type: text/html
X-Plex-Protocol: 1.0
```
