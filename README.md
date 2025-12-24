<h1>Setting Up Synology Reverse Proxy for your LAN</h1>
I was finally able to get the Synology Reverse Proxy to work for my local LAN.  <br>

<br>
Here is my setup:
<br>
<h2>Firewall (local DNS server):</h2>
On the Firewalla, setup a custom DNS entry that points my home domain to my NAS IP. e.g.  <code>myhome.land → 10.10.0.23 </code> <br>
<br>
This is essentially an "A" record.
<br>
<h2>Reverse Proxy</h2>

Then in <em>Synology | Control Panel | Login Portal | Advanced | Reverse Proxy</em>, Create two entries. One to redirect HTTP to HTTPS, the second to redirect HTTPS to the right server/port. 
<br><br>
Here are two examples, one for a container on my Synology NAS, the other on an Raspberry Pi on my LAN:<br>
<br>
<h3>Plex (on NAS):</h3>
<ol>
<li>Redirect http://plex.myhome.land:80 to https://plex.myhome.land:443</li>
<li>Redirect https://plex.myhome.land:443 to https://localhost:32400<br></li>
</ol>
<h3>Portainer (on Rpi):</h3>
<ol>
<li>Redirect http://portainer.myhome.land:80 to https://portainer.myhome.land:443/li>
<li>Redirect https://portainer.myhome.land:443 to https://10.10.0.130:9443<br>
</ol>

<br>
For the HTTP connections, make sure to add a Websocket Custom Header.
<br><br>
Now, you can type in <em>plex.myhome.land</em> or <em>portainer.myhome.land</em> in any browser on my LAN and it resolves.
<br>
<h2>/etc/hosts</h2>
<br>
You can run the <em>create_etc_hosts_file.sh</em> script to create a new <em>/etc/hosts</em> file to drop on your local devices, which makes it a bit more reliable. 
It reads the Reverse Proxy JSON file and creates a /etc/hosts. (Written with help from Lumo from Proton - https://lumo.proton.me ).<br>
<br>
You can also use the script to double check your Reverse Proxy setup.<br>
<br>
For Plex and Portainer, you should see:<br>
<br><code>10.10.0.23  plex.myhome.land               # redirect http → https AND https → https://localhost:32400<br>
10.10.0.23  portainer.myhome.land          # redirect http → https AND https → https://10.10.0.130:9443<br>
</code>
<br>
<h2>How (I think) it works</h2>
<br>
When you type in any URL that ends in "myhome.lan" on your LAN, the DNS server (my Firewalla) will redirect the traffic to the IP address of the Synology NAS.On the Synology NAS, the Reverse Proxy then gets the traffic and (if it is HTTP), redirects it to the same URL but as HTTPS. It will also add the Websocket custom headers (if you remembered to do that.)
<br><br>Then it gets the HTTPS traffic, and redirects it to either a port on the Synology NAS or to the IP address/Port of a remote host.
