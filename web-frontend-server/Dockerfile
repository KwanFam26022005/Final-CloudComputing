FROM nginx:stable

ENV SERVER_NODE_NAME="unknown"

RUN rm -f /etc/nginx/conf.d/default.conf

COPY conf.default /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh \
    && chmod -R 755 /usr/share/nginx/html

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]