FROM nginx:stable

ARG SERVER_NODE_NAME="web-frontend-server1 (Primary)"
ENV SERVER_NODE_NAME=${SERVER_NODE_NAME}

RUN rm -f /etc/nginx/conf.d/default.conf
COPY conf.default /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

# Nhúng tên Node vào trang chủ và cấu hình Nginx để minh chứng Load Balancing Round Robin (Mở rộng #10)
RUN sed -i "s/__SERVER_NODE_NAME__/${SERVER_NODE_NAME}/g" /usr/share/nginx/html/index.html /etc/nginx/conf.d/default.conf \
    && chmod -R 755 /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
