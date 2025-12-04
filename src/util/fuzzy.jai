#import "Basic";
#import "String";

Fuzzy_Match :: struct {
    score: int;
    matched_indices: [..]int;
    matched: bool;
}

// Returns a high score for better matches.
// score > 0 means match.
fuzzy_search :: (pattern: string, text: string) -> Fuzzy_Match {
    result: Fuzzy_Match;
    
    if pattern.count == 0 {
        result.matched = true;
        result.score = 0;
        return result;
    }
    
    if text.count == 0 {
        result.matched = false;
        return result;
    }

    // Simple recursive or matrix-based approach is too heavy? 
    // Let's do a simple greedy scan first, then rank.
    // Actually, fzf uses a modified Smith-Waterman.
    // For this UI demo, a simple "all characters must exist in order" + scoring is enough.

    pidx := 0;
    tidx := 0;
    score := 0;
    consecutive := 0;
    
    // Normalize case for matching (but we don't have a full unicode folder yet, simple ascii lower)
    // We'll do case-insensitive comparison character by character.
    
    first_match_index := -1;

    while pidx < pattern.count && tidx < text.count {
        p_char := char_to_lower(pattern[pidx]);
        t_char := char_to_lower(text[tidx]);

        if p_char == t_char {
            array_add(*result.matched_indices, tidx);
            
            // Scoring logic
            current_score := 10;
            
            // Bonus for start of string
            if tidx == 0 {
                current_score += 20;
            }
            
            // Bonus for consecutive matches
            if consecutive > 0 {
                current_score += 5 * consecutive;
            }
            
            // Bonus for word boundary (after space or separator)
            if tidx > 0 {
                prev := text[tidx - 1];
                if prev == #char " " || prev == #char "/" || prev == #char "-" {
                    current_score += 10;
                }
            }

            score += current_score;
            consecutive += 1;
            pidx += 1;
            
            if first_match_index == -1 first_match_index = tidx;
        } else {
            consecutive = 0;
        }
        tidx += 1;
    }

    if pidx == pattern.count {
        result.matched = true;
        // Penalty for string length to prefer shorter matches
        score -= (text.count - pattern.count); 
        result.score = score;
    } else {
        result.matched = false;
        array_reset(*result.matched_indices); // clear any partial matches
    }
    
    return result;
}

// Helper for case-insensitive comparison
// Note: This is ASCII only for simplicity
char_to_lower :: (c: u8) -> u8 {
    if c >= #char "A" && c <= #char "Z" {
        return c + 32;
    }
    return c;
}
