#!/bin/sh

gst-launch-1.0 videotestsrc pattern="ball" ! x265enc ! rtph265pay ! udpsink host=127.0.0.1 port=5021 &
sleep 1
gst-launch-1.0 videotestsrc pattern="pinwheel" ! x265enc ! rtph265pay ! udpsink host=127.0.0.1 port=5022 &
sleep 1
gst-launch-1.0 videotestsrc pattern="snow" ! x265enc ! rtph265pay ! udpsink host=127.0.0.1 port=5031 &
sleep 1
gst-launch-1.0 videotestsrc pattern="spokes" ! x265enc ! rtph265pay ! udpsink host=127.0.0.1 port=5032 &

