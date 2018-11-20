FROM nginx:stable-alpine

COPY etc/nginx/* /etc/nginx/
COPY entrypoint.sh /root/entrypoint.sh

RUN chmod 775 /root/entrypoint.sh

ENV AWSHOST kinesis.us-east-1.amazonaws.com

EXPOSE 443

CMD ["/root/entrypoint.sh"]


