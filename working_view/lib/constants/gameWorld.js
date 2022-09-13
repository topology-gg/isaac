// Universe parameters
export const CIV_SIZE = 10


//
// Sizes
//
export const SIDE = 100 // number of grids per size (planet dimension)
export const GRID = Math.floor (300 / SIDE) // grid size
export const PAD_X = 160 // pad size
export const PAD_Y = 90 // pad size
export const CANVAS_W = 1122
export const CANVAS_H = 900
export const TRIANGLE_W = 6
export const TRIANGLE_H = 10
export const GRID_SPACING = 5
export const DEVICE_STROKE_WIDTH = 0.25

//
// Theme / Stlyes
//
export const PALETTE = 'DARK'
export const HOVER_DEVICE_COLOR = PALETTE === 'DARK' ? '#FFFFFF' : '#22d3ee'
export const FILL_CURSOR_GRID   = PALETTE === 'DARK' ? '#AAAAAA55' : '#AAAAAA55';
export const STROKE_CURSOR_FACE = PALETTE === 'DARK' ? '#FFEFD5' : '#999999';
export const STROKE             = PALETTE === 'DARK' ? '#DDDDDD' : '#BBBBBB' // grid stroke color
// export const CANVAS_BG          = PALETTE === 'DARK' ? '#181818' : '#E3EDFF'
export const CANVAS_BG = '#1b2737'
export const GRID_ASSIST_TBOX   = PALETTE === 'DARK' ? '#CCCCCC' : '#333333'
export const FILL_CURSOR_SELECTED_GRID   = PALETTE === 'DARK' ? '#DDDDDD55' : '#AAAAAA55'

//
// Animation
//
export const ANIM_UPDATE_INTERVAL_MS = 150

//
// Stroke widths
//
export const STROKE_WIDTH_CURSOR_FACE = 1.5
export const STROKE_WIDTH_AXIS = 0.4
export const STROKE_WIDTH_GRID_COURSE = 0.2
export const STROKE_WIDTH_GRID_MEDIUM = 0.25
export const STROKE_WIDTH_GRID_FINEST = 0.02
export const STROKE_WIDTH_GRID_FACE = 0.4
export const HOVER_DEVICE_STROKE_WIDTH = 0.8

//
// Sound effect
//
export const VOLUME = 0.2
