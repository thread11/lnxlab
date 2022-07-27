import datetime
import re
import xml.etree.ElementTree

download_mp3_incre_sh = open('download_mp3_incre.sh', 'w')
download_mp3_full_sh = open('download_mp3_full.sh', 'w')

xml = xml.etree.ElementTree.parse('stackoverflow_podcast.xml')
rss = xml.getroot()

for children in rss:
    if children.tag == 'channel':
        channel = children

        for children2 in channel:
            if children2.tag == 'item':
                item = children2

                title_text = None
                pubDate_text = None
                enclosure_url = None
                itunes_episode_text = None

                for children3 in item:
                    if children3.tag == 'pubDate':
                        pubDate = children3
                        pubDate_text = pubDate.text

                    if children3.tag == '{http://www.itunes.com/dtds/podcast-1.0.dtd}episode':
                        itunes_episode = children3
                        itunes_episode_text = itunes_episode.text

                    if children3.tag == 'title':
                        title = children3
                        title_text = title.text

                    if children3.tag == 'enclosure':
                        enclosure = children3
                        enclosure_url = enclosure.get('url')
                        enclosure_length = enclosure.get('length')

                pubDate_text = datetime.datetime.strptime(pubDate_text, '%a, %d %b %Y %H:%M:%S +0000').strftime('%Y%m%dT%H%M%S')

                if itunes_episode_text is not None:
                    itunes_episode_text = '%04d' % int(itunes_episode_text)

                title_text = title_text.replace(' ', '_')
                title_text = re.sub(r'[^0-9a-zA-Z]+', '_', title_text)
                title_text = re.sub(r'^_|_$', '', title_text)

                mp3 = '%s__%s__%s__%s.mp3' % (pubDate_text, itunes_episode_text, enclosure_length, title_text)

                line = '[ ! -f "%s" ] && wget -c "%s" -O %s' % (mp3, enclosure_url, mp3)
                download_mp3_incre_sh.write(line)
                download_mp3_incre_sh.write('\n')
                download_mp3_incre_sh.write('\n')

                line = 'wget -c "%s" -O %s' % (enclosure_url, mp3)
                download_mp3_full_sh.write(line)
                download_mp3_full_sh.write('\n')
                download_mp3_full_sh.write('\n')

download_mp3_incre_sh.close()
download_mp3_full_sh.close()
