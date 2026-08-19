const express = require('express');
const youtubedl = require('youtube-dl-exec');
const app = express();
const port = 3000;

process.on('uncaughtException', (err) => console.error('[CRITICAL] Uncaught Exception:', err.message));
process.on('unhandledRejection', (reason, promise) => console.error('[CRITICAL] Unhandled Rejection:', reason));

const activeStreams = {};

app.get('/play', (req, res) => {
    const videoUrl = req.query.url;
    const token = req.query.token;

    // SISTEM ANTI MALING BANDWIDTH
    if (token !== 'bbb_premium_889') {
        return res.status(403).send('Access Denied: Invalid Token');
    }

    if (!videoUrl) return res.status(400).send('Invalid URL');

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
                'match-filter': 'duration <= 600', // LIMIT MAX 10 MENIT
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
    console.log(`Boombox API running on port ${port}`);
});
