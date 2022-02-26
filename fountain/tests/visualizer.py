import pygame, sys
import numpy as np
import subprocess
import time
import json
from math import sqrt
from timeit import default_timer as timer

def print_system_state(state):
    print_ball_state(state['s1'])
    print_ball_state(state['s2'])
    print_ball_state(state['s3'])
    print_ball_state(state['fb'])
    print_ball_state(state['pl'])

def print_ball_state(state):
    x = state['x']
    y = state['y']
    vx = state['vx']
    vy = state['vy']
    ax = state['ax']
    ay = state['ay']
    print(f'x={x}, y={y}, vx={vx}, vy={vy}, ax={ax}, ay={ay}')

# utility function to execute shell command and parse result
def subprocess_run (cmd):
	result = subprocess.run(cmd, stdout=subprocess.PIPE)
	result = result.stdout.decode('utf-8')[:-1] # remove trailing newline
	return result

def gradientBG(screen):
	""" Draw a horizontal-gradient filled rectangle covering <target_rect> """
	target_rect = pygame.Rect(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
	color_rect = pygame.Surface( (2,2) )
	pygame.draw.line( color_rect, BG_TOP_COLOR,  (0,0), (1,0) ) # top color line
	pygame.draw.line( color_rect, BG_BOTTOM_COLOR, (0,1), (1,1) ) # bottom color line
	color_rect = pygame.transform.smoothscale( color_rect, (target_rect.width,target_rect.height ) )  # stretch
	screen.blit( color_rect, target_rect ) # paint

# text box initialization
def update_game_message (message, screen):
	font = pygame.font.Font(None, 16)
	text = font.render(message, 1, (255, 255, 255))
	text_rect = text.get_rect(center =(SCREEN_WIDTH / 2, SCREEN_HEIGHT + GAME_TEXT_HEIGHT/2))
	screen.fill ((30, 30, 30), (0, SCREEN_HEIGHT, SCREEN_WIDTH, GAME_TEXT_HEIGHT))
	screen.blit(text, text_rect)
	pygame.display.update()

def update_stat_message (message, screen):
	font = pygame.font.Font(None, 16)
	text = font.render(message, 1, (255, 255, 255))
	text_rect = text.get_rect(center =(SCREEN_WIDTH / 2, SCREEN_HEIGHT + GAME_TEXT_HEIGHT + STAT_TEXT_HEIGHT/2))
	screen.fill ((1, 1, 1), (0, SCREEN_HEIGHT+GAME_TEXT_HEIGHT, SCREEN_WIDTH, STAT_TEXT_HEIGHT))
	screen.blit(text, text_rect)
	pygame.display.update()

# redraw the screen and the mass at new x location
def update_figures(ball_xy_s, ball_queue_s, screen):

	SCALE = 1
	gradientBG(screen)
	n_ball = len(ball_xy_s)

	# enqueue & dequeue; leave N circles in trail; insert from head
	N_TRAIL_CIRCLES = 1
	if len(ball_queue_s[0])==N_TRAIL_CIRCLES:
		for i in range(n_ball):
			ball_queue_s[i] = [ball_xy_s[i]] + ball_queue_s[i][0:-1]
	else:
		for i in range(n_ball):
			ball_queue_s[i] = [ball_xy_s[i]] + ball_queue_s[i]

	# transform from simulation coordinate to visualization
	#f_transform_x = lambda x : SCREEN_CENTER + (x-X_CENTER)*SCALE
	#f_transform_y = lambda y : SCREEN_CENTER - (y-Y_CENTER)*SCALE
	f_transform_x = lambda x : x
	f_transform_y = lambda y : SCREEN_HEIGHT - y

	# draw the walls
	#pygame.draw.rect ( screen, (1,1,1), (0, 0, 100+BALL_RADIUS*2, 600) )
	#pygame.draw.rect ( screen, (1,1,1), (0, 0, 600, 100+BALL_RADIUS*2) )
	#pygame.draw.rect ( screen, (1,1,1), (0, 500+BALL_RADIUS*2, 600, 100+BALL_RADIUS*2) )
	#pygame.draw.rect ( screen, (1,1,1), (500+BALL_RADIUS*2, 0, 100+BALL_RADIUS*2, 600) )

	# draw the point mass
	for i in range(n_ball):
		circle_img = pygame.Surface((BALL_RADIUS*2*SCALE,BALL_RADIUS*2*SCALE))
		pygame.draw.circle(circle_img, BALL_COLOR_S[i], (BALL_RADIUS*SCALE,BALL_RADIUS*SCALE), BALL_RADIUS*SCALE)
		circle_img.set_colorkey(0)
		for j in range(len(ball_queue_s[i])):
			x = f_transform_x (ball_queue_s[i][j][0])
			y = f_transform_y (ball_queue_s[i][j][1])

			if j==0:
				circle_img.set_alpha(255)
			else:
				circle_img.set_alpha(250 * ( 1-j**2/N_TRAIL_CIRCLES**2 ))
			screen.blit(circle_img, (x-BALL_RADIUS*SCALE,y-BALL_RADIUS*SCALE)) # coordinate is top-left of circle_img

	pygame.display.update()
	ball_queue_s_nxt = ball_queue_s
	return ball_queue_s_nxt

# scene setup
SCREEN_WIDTH = 250
SCREEN_CENTER = SCREEN_WIDTH/2
SCREEN_HEIGHT = 250

GAME_TEXT_HEIGHT = 75
STAT_TEXT_HEIGHT = 75
SCREEN_HEIGHT_TOTAL = SCREEN_HEIGHT + GAME_TEXT_HEIGHT + STAT_TEXT_HEIGHT
BALL_RADIUS = 20

BG_TOP_COLOR = (132,203,185)
BG_BOTTOM_COLOR = (201,230,225)

COLOR_LEMON = (255,231,107)
COLOR_TAN = (240,143,62)
COLOR_BURNT = (229,78,48)
COLOR_CREAM = (255,248,211)
COLOR_GRAY = (85,74,82)
BALL_COLOR_S = [
	COLOR_LEMON,
	COLOR_TAN,
	COLOR_GRAY,
	COLOR_CREAM
]

# contract setup
#CONTRACT_ADDRESS = '0x7235ef9bcca5e92bd069b4bb2280b2ff2ce377ab48450968f47c747b3282fa5'
#BATCH_CONTRACT_ADDRESS = '0x78aee401a2283bebf0ceb97e881150dad0a47d8d58943d452d87b35dbef105'
FP = 10 ** 12
#PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
#PRIME_HALF = PRIME//2

def adjust_fp (x):
	return x/FP

def visualize_game (arr_obj_s, msg, loop=False):

	pygame.init()
	screen = pygame.display.set_mode( (SCREEN_WIDTH, SCREEN_HEIGHT_TOTAL) )
	gradientBG(screen)
	update_game_message(msg, screen)
	pygame.display.set_caption('visualization')

	clock = pygame.time.Clock()
	dt = 0.1


	ball_queue_s = {}
	for i in range( len(arr_obj_s[0]) ):
		ball_queue_s[i] = [] # empty queue

	while True:
		update_stat_message('visualizing ...', screen)
		time.sleep(1)

		for arr_obj in arr_obj_s:
			ball_xy_s = [ (adjust_fp(obj.pos.x), adjust_fp(obj.pos.y)) for obj in arr_obj]
			ball_queue_s = update_figures(
				ball_xy_s,
				ball_queue_s,
				screen
			)
			time.sleep(dt)

		update_stat_message('visualization ended', screen)

		if loop:
			time.sleep(1)
		else:
			break

	pygame.display.quit()
	pygame.quit()
