#import "Basic";
// widgets.jai, fuzzy.jai loaded from main.jai

Results_List :: struct {
    rect: Rect;
    items: [..]Search_Item; // Filtered items
    selected_index: int;
    
    // Animation state for scroll
    scroll_offset: float;
    target_scroll_offset: float;
    
    match_indices: [..][..]int; // Indices for highlighting per item
}

init_results_list :: (list: *Results_List, x: float, y: float, w: float, h: float) {
    list.rect = make_rect(x, y, w, h);
    list.selected_index = 0;
}

update_results :: (list: *Results_List, all_items: []Search_Item, query: string) {
    // Clear current
    array_reset(*list.items);
    for list.match_indices array_reset(*it);
    array_reset(*list.match_indices);
    
    // Fuzzy Search
    // Define a struct to hold score for sorting
    Scored_Item :: struct {
        index: int;
        score: int;
        matches: [..]int;
    }
    
    scores: [..]Scored_Item;
    defer array_free(scores); // Assuming simple defer free pattern
    
    for i: 0..all_items.count-1 {
        match := fuzzy_search(query, all_items[i].text);
        if match.matched {
            scored: Scored_Item;
            scored.index = i;
            scored.score = match.score;
            // Copy matches
            array_copy(*scored.matches, match.matched_indices);
            array_add(*scores, scored);
        }
    }
    
    // Sort by score (Bubble sort for simplicity or qsort)
    // Using bubble sort for tiny list
    for i: 0..scores.count-1 {
        for j: 0..scores.count-2-i {
            if scores[j].score < scores[j+1].score {
                swap(*scores[j], *scores[j+1]);
            }
        }
    }
    
    // Take top 10
    limit := min(scores.count, 10);
    for 0..limit-1 {
        idx := scores[it].index;
        array_add(*list.items, all_items[idx]);
        
        // Store highlights
        // We need to copy the inner dynamic array to keep it
        indices_copy: [..]int;
        array_copy(*indices_copy, scores[it].matches);
        array_add(*list.match_indices, indices_copy);
    }
    
    // Cleanup matched_indices in scores that weren't used? 
    // (Omitted for brevity, standard arena allocator would handle this well)
    
    list.selected_index = 0;
}

render_results_list :: (list: *Results_List, ctx: *Renderer_Context) {
    row_height := 40.0;
    
    // Draw background
    // draw_rect_rounded(ctx, list.rect, current_theme.background, 8.0);
    
    // Draw items
    start_y := list.rect.y;
    
    for list.items {
        row_rect := make_rect(list.rect.x, start_y + it_index * row_height, list.rect.w, row_height);
        
        is_selected := (it_index == list.selected_index);
        
        highlights: []int;
        if it_index < list.match_indices.count {
            highlights = list.match_indices[it_index];
        }
        
        draw_result_row(ctx, row_rect, it, is_selected, highlights);
    }
}

move_selection :: (list: *Results_List, delta: int) {
    list.selected_index += delta;
    if list.selected_index < 0 list.selected_index = 0;
    if list.selected_index >= list.items.count list.selected_index = max(list.items.count - 1, 0);
}
