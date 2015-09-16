function video-upload() {
  if [ $# -lt 1 ]; then
    echo "[ERROR] Missing requried file name."
  else
    FILESIZE=$(stat -c%s "$1")
    printf "[START] Uploading $FILESIZE bytes.\n"
    MEDIAID=$(twurl /1.1/media/upload.json -H upload.twitter.com -d "command=INIT&media_type=video/mp4&total_bytes=$FILESIZE" | jq .media_id_string | sed 's/\"//g')

    INDEX=0
    split -b 3m $1 twitter-video-
    for FILE in twitter-video-*; do
      echo "[INFO] Uploading segment $INDEX ($FILE)..."
      twurl "/1.1/media/upload.json" -H upload.twitter.com -d "command=APPEND&segment_index=$INDEX&media_id=$MEDIAID" --file-field "media" --file "$FILE"
      INDEX=$((INDEX + 1))
    done
    rm twitter-video-*

    twurl "/1.1/media/upload.json" -H upload.twitter.com -d "command=FINALIZE&media_id=$MEDIAID" && printf "\n"
    printf "[DONE] $MEDIAID"
  fi
}