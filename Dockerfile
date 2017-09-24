FROM stilliard/pure-ftpd

MAINTAINER macmacs https://github.com/macmacs

COPY run.sh /run.sh
# COPY init-user.sh /init-user.sh
RUN chmod u+x /run.sh
# RUN chmod u+x /init-user.sh
