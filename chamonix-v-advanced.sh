# export MallocStackLogging=true
LOG="cutechess-$(date +%Y-%m-%d_%H%M%S).log"
cutechess-cli \
    -engine name=ChamonixAdvanced cmd=/Users/swart/Chess/Chamonix-Advanced/Products/usr/local/bin/Chamonix debug \
    -engine name=ChamonixSimple cmd=/Users/swart/Chess/Chamonix-Simple/Products/usr/local/bin/Chamonix debug \
    -each proto=uci tc=10+0.1 \
    -openings file=Modern.pgn order=random plies=12 \
    -games 200 \
    -repeat \
    -pgnout games.pgn \
    -recover \
    2>&1 | tee "$LOG"

#    -openings file=book.pgn format=pgn \
