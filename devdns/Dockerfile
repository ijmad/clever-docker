FROM ubuntu
EXPOSE 53
RUN apt-get update && apt-get install -y dnsmasq
RUN rm /etc/dnsmasq.conf && touch /etc/dnsmasq.conf
CMD dnsmasq --no-daemon
