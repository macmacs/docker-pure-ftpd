
Docker Pure-ftpd Server - OpenShift ready!
============================


[![Build Status](https://travis-ci.org/macmacs/docker-pure-ftpd.svg?branch=master)](https://travis-ci.org/macmacs/docker-pure-ftpd)
[![Docker Build Status](https://img.shields.io/docker/build/macmacs/pure-ftpd.svg)](https://hub.docker.com/r/macmacs/pure-ftpd/)
[![Docker Pulls](https://img.shields.io/docker/pulls/macmacs/pure-ftpd.svg)](https://hub.docker.com/r/macmacs/pure-ftpd/)

Pull down with docker:
```bash
docker pull macmacs/pure-ftpd:hardened
```

**Often needing to run as `sudo`, e.g. `sudo docker pull macmacs/pure-ftpd`**

----------------------------------------

**My advice is to extend this image to make any changes.**  
This is because rebuilding the entire docker image via a fork can be slow as it rebuilds the entire pure-ftpd package from source. 

Instead you can create a new project with a `DOCKERFILE` like so:

```
FROM macmacs/pure-ftpd

# e.g. you could change the defult command run:
CMD /run.sh -c 30 -C 10 -l puredb:/etc/pure-ftpd/pureftpd.pdb -E -j -R -P $PUBLICHOST -p 30000:30059
```

*Then you can build your own image, `docker build --rm -t my-pure-ftp .`, where my-pure-ftp is the name you want to build as*

----------------------------------------

Starting it 
------------------------------

`docker run -d --name ftpd_server -p 21:21 -p 30000-30009:30000-30009 -e "PUBLICHOST=localhost" macmacs/pure-ftpd:hardened`

*Or for your own image, replace macmacs/pure-ftpd with the name you built it with, e.g. my-pure-ftp*

You can also pass ADDED_FLAGS as an env variable to add additional options such as --tls to the pure-ftpd command.  
e.g. ` -e "ADDED_FLAGS=--tls=2" `


Operating it
------------------------------

`docker exec -it ftpd_server /bin/bash`

Example usage once inside
------------------------------

Create an ftp user: `e.g. bob with chroot access only to /home/ftpusers/bob`
```bash
pure-pw useradd bob -f /etc/pure-ftpd/passwd/pureftpd.passwd -m -u ftpuser -d /home/ftpusers/bob
```
*No restart should be needed.*

*If you have any trouble with volume permissions due to the **uid** or **gid** of the created user you can change the **-u** flag for the uid you would like to use and/or specify **-g** with the group id as well. For more information see issue [#35](https://github.com/macmacs/docker-pure-ftpd/issues/35#issuecomment-325583705).*

More info on usage here: https://download.pureftpd.org/pure-ftpd/doc/README.Virtual-Users


Test your connection
-------------------------
From the host machine:
```bash
ftp -p localhost 21
```

Max clients
-------------------------
By default we set 5 max clients at once, but you can increase this by increasing `-c 5`, e.g. to `-c 50` and then also increasing the number of public ports opened from `-p 30000:30009` `-p 30000:30099`. You'll also want to open those ports when running docker run.


Logs
-------------------------
To get verbose logs add the following to your `docker run` command:
```
-e "ADDED_FLAGS=-d -d"
```

Then if you exec into the container you could watch over the log with `tail -f /var/log/messages`

Want a transfer log file? add the following to your `docker run` command:
```bash
-e "ADDED_FLAGS=-O w3c:/var/log/pure-ftpd/transfer.log"
```

----------------------------------------

Tags available for different versions
--------------------------------------

**Latest versions**

- `latest` - latest working version
- `jessie-latest` - latest but will always remain on debian jessie
- `hardened` - latest + [more secure/hardened defaults](https://github.com/macmacs/docker-pure-ftpd/issues/10)

**Previous version before tags were introduced**

- `wheezy-1.0.36` - incase you want to roll back to before we started using debian jessie

**Specific pure-ftpd versions**

- `jessie-1.x.x` - jessie + specific versions, e.g. jessie-1.0.36
- `hardened-1.x.x` - hardened + specific versions

*Check the tags on github for available versions, feel free to submit issues and/or pull requests for newer versions*

Usage of specific tags: 
`sudo docker pull macmacs/pure-ftpd:hardened-1.0.36`

----------------------------------------

Our default pure-ftpd options explained
----------------------------------------

```
/usr/sbin/pure-ftpd # path to pure-ftpd executable
-c 5 # --maxclientsnumber (no more than 5 people at once)
-C 5 # --maxclientsperip (no more than 5 requests from the same ip)
-l puredb:/etc/pure-ftpd/pureftpd.pdb # --login (login file for virtual users)
-E # --noanonymous (only real users)
-j # --createhomedir (auto create home directory if it doesnt already exist)
-R # --nochmod (prevent usage of the CHMOD command)
-P $PUBLICHOST # IP/Host setting for PASV support, passed in your the PUBLICHOST env var
-p 30000:30009 # PASV port range (10 ports for 5 max clients)
-tls 1 # Enables optional TLS support
```

For more information please see `man pure-ftpd`, or visit: https://www.pureftpd.org/

Why so many ports opened?
---------------------------
This is for PASV support, please see: [#5 PASV not fun :)](https://github.com/macmacs/docker-pure-ftpd/issues/5)

----------------------------------------

Docker Volumes
--------------
There are a few spots onto which you can mount a docker volume to configure the
server and persist uploaded data. It's recommended to use them in production. 

  - `/home/ftpusers/` The ftp's data volume (by convention). 
  - `/etc/pure-ftpd/passwd` A directory containing the single `pureftps.passwd`
    file which contains the user database (i.e., all virtual users, their
    passwords and their home directories). This is read on startup of the
    container and updated by the `pure-pw useradd -f /etc/pure-
    ftpd/passwd/pureftpd.passwd ...` command.
  - `/etc/ssl/private/` A directory containing a single `pure-ftpd.pem` file
    with the server's SSL certificates for TLS support. Optional TLS is
    automatically enabled when the container finds this file on startup.

Keep user database in a volume
------------------------------
You may want to keep your user database through the successive image builds. It is possible with Docker volumes.

Create a named volume:
```
docker volume create --name my-db-volume
```

Specify it when running the container:
```
docker run -d --name ftpd_server -p 21:21 -p 30000-30009:30000-30009 -e "PUBLICHOST=localhost" -v my-db-volume:/etc/pure-ftpd/passwd macmacs/pure-ftpd:hardened
```

When an user is added, you need to use the password file which is in the volume:
```
pure-pw useradd bob -f /etc/pure-ftpd/passwd/pureftpd.passwd -m -u ftpuser -d /home/ftpusers/bob
```
(Thanks to the -m option, you don't need to call *pure-pw mkdb* with this syntax).


Changing a password
---------------------
e.g. to change the password for user "bob":
```
pure-pw passwd bob -f /etc/pure-ftpd/passwd/pureftpd.passwd -m
```

----------------------------------------
Development (via git clone)
```bash
# Clone the repo
git clone https://github.com/macmacs/docker-pure-ftpd.git
cd docker-pure-ftpd
# Build the image
make build
# Run container in background:
make run
# enter a bash shell insdie the container:
make enter
```

TLS
----

If you want to enable tls (for ftps connections), you need to have a valid
certificate. You can get one from one of the certificate authorities that you'll
find when googling this topic. The certificate (containing private key and
certificate) needs to be at:

```
/etc/ssl/private/pure-ftpd.pem
```

Use docker volumes to get the certificate there at runtime. The container will
automatically enable optional TLS when it detect the file at this location.

You can also self-sign a certificate, which is certainly the easiest way to
start out. Self signed certificates come with certain drawbacks, but it might
be better to have a self signed one than none at all.

Here's how to create a self-signed certificate from within the container:

```bash
mkdir -p /etc/ssl/private
openssl dhparam -out /etc/ssl/private/pure-ftpd-dhparams.pem 2048
openssl req -x509 -nodes -newkey rsa:2048 -sha256 -keyout \
    /etc/ssl/private/pure-ftpd.pem \
    -out /etc/ssl/private/pure-ftpd.pem
chmod 600 /etc/ssl/private/*.pem
```


Credits
-------------
Thanks for the help on stackoverflow with this!
https://stackoverflow.com/questions/23930167/installing-pure-ftpd-in-docker-debian-wheezy-error-421

