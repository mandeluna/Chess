# export MallocStackLogging=true
LOG="cutechess-$(date +%Y-%m-%d_%H%M%S).log"
cutechess-cli \
    -engine name=Stockfish cmd=/opt/homebrew/bin/stockfish \
    -engine name=Chamonix cmd=/Users/swart/Chess/Chamonix/Products/usr/local/bin/Chamonix debug \
    -each proto=uci tc=10+0.1 \
    -games 100 \
    -repeat \
    -pgnout games.pgn \
    -recover \
    2>&1 | tee "$LOG"

#    -openings file=book.pgn format=pgn \
