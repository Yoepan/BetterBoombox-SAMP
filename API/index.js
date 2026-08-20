const express = require('express');
const youtubedl = require('youtube-dl-exec');
const play = require('play-dl');
const spotifyUrlInfo = require('spotify-url-info')(fetch);
const app = express();
const port = 3000;

process.on('uncaughtException', (err) => console.error('[CRITICAL] Uncaught Exception:', err.message));
process.on('unhandledRejection', (reason, promise) => console.error('[CRITICAL] Unhandled Rejection:', reason));

const activeStreams = {};

app.get('/play', async (req, res) => {
    let videoUrl = req.query.url;
    const token = req.query.token;

    console.log(`[BetterBoombox] Incoming Request | Token: ${token} | URL: ${videoUrl}`);

    // ANTI-LEECH BANDWIDTH SYSTEM
    if (token !== 'bbb_premium_889') {
        console.log(`[BetterBoombox] ACCESS DENIED: Invalid Token!`);
        return res.status(403).send('Access Denied: Invalid Token');
    }

    if (!videoUrl) return res.status(400).send('Invalid URL');

    if (videoUrl.includes('list=')) {
        console.log(`[BetterBoombox] Blocked YouTube Playlist`);
        return res.status(400).send('Playlists are not supported.');
    }

    if (videoUrl.includes('spotify.com/')) {
        if (!videoUrl.includes('/track/')) {
            console.log(`[BetterBoombox] Blocked Spotify Playlist/Album`);
            return res.status(400).send('Only single tracks are supported, not playlists or albums.');
        }

        try {
            console.log(`[BetterBoombox] Spotify link detected. Fetching metadata...`);
            let sp_data = await spotifyUrlInfo.getPreview(videoUrl);
            let search_query = `${sp_data.title} ${sp_data.artist} audio`;
            console.log(`[BetterBoombox] Spotify -> Searching YouTube: "${search_query}"`);
            
            let yt_info = await play.search(search_query, { limit: 1 });
            if (yt_info && yt_info.length > 0) {
                videoUrl = yt_info[0].url;
                console.log(`[BetterBoombox] Converted Spotify to YouTube URL: ${videoUrl}`);
            } else {
                return res.status(404).send('Spotify track not found on YouTube');
            }
        } catch (err) {
            console.error('[ERROR] Spotify conversion failed:', err.message);
            return res.status(500).send('Error converting Spotify link');
        }
    }
    // ==============================================

    res.setHeader('Content-Type', 'audio/mp4');
    res.setHeader('Transfer-Encoding', 'chunked');

    if (activeStreams[videoUrl]) {
        activeStreams[videoUrl].listeners.push(res);
    } else {
        const MAX_CONCURRENT_STREAMS = 40;
        if (Object.keys(activeStreams).length >= MAX_CONCURRENT_STREAMS) {
            return res.status(503).send('Capacity reached');
        }

        try {
            const subprocess = youtubedl.exec(videoUrl, {
                o: '-',
                f: '18',
                'extractor-args': 'youtube:player_client=android',
                'match-filter': 'duration <= 600', // LIMIT MAX 10 MINS
                'js-runtimes': 'node',
            }, { stdio: ['ignore', 'pipe', 'ignore'] });

            activeStreams[videoUrl] = {
                process: subprocess,
                listeners: [res]
            };

            subprocess.stdout.on('data', (chunk) => {
                if (activeStreams[videoUrl]) {
                    activeStreams[videoUrl].listeners.forEach(listener => {
                        if (!listener.writableEnded && !listener.destroyed) {
                            listener.write(chunk);
                        }
                    });
                }
            });

            subprocess.on('close', () => {
                if (activeStreams[videoUrl]) {
                    activeStreams[videoUrl].listeners.forEach(l => l.end());
                    delete activeStreams[videoUrl];
                }
            });

            subprocess.catch(err => console.error('[ERROR] yt-dlp:', err.message));

        } catch (error) {
            return res.status(500).send('Error');
        }
    }

    req.on('close', () => {
        if (activeStreams[videoUrl]) {
            activeStreams[videoUrl].listeners = activeStreams[videoUrl].listeners.filter(l => l !== res);
            if (activeStreams[videoUrl].listeners.length === 0) {
                activeStreams[videoUrl].process.kill('SIGKILL');
                delete activeStreams[videoUrl];
            }
        }
    });
});

app.listen(port, () => {
    console.log(`[BetterBoombox] API Server is running on port ${port}`);
});
