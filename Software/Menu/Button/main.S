/*
 *  Hamed Mirlohi
 *  Box Detection and Image Replacement Final Project
 * 	Last Modified: 3/22/2019
 *
 * 	Description:
	Implented GUI using seven sagments and Buttons to control the menu.
 *  ============
 *  
*/


# ======================
# === Port Addresses ===
# ======================

# Nexys 4 board base I/O interface ports compatible with the Nexy$4 I/O interface
# Port Addresses

PORT_SLSWTCH		= 0xbf800004		# (i) slide switches
PORT_PBTNS 			= 0xbf800008		# (i) pushbuttons inputs

# ========================================================================
# Change the following port address, as implemented by you in the hardware
# ========================================================================

PORT_SEVENSEG_EN 	= 0xbf700000		# (o) 7 Segment enable
PORT_SEVENSEG_HGH	= 0xbf700004		# (o) 7 Segment Higher Display
PORT_SEVENSEG_LOW	= 0xbf700008		# (o) 7 Segment Lower Display
PORT_SEVENSEG_DP	= 0xbf70000c		# (o) 7 segment Decimal Point Display

# =============================
# === State Constants For Push-Buttons
# =============================

SM_RESET_CAM			= 0x00
SM_ENABLE_DISABLE 		= 0x01
SM_BLUE_GREEN 			= 0x02
SM_IMG 					= 0x03

ENABLE					= 0xE1C
BLUE					= 0xB1A
IMAGE_ONE				= 0x1


# State variable
CURRENT_STATE_CAM:			.byte	0

.text
.globl main
main:
				add	$23, $0, ENABLE				// initialize disable mode to En
				add $20, $0, BLUE				// initialize color select to Bl,
				add $19, $0, IMAGE_ONE			// initialize image select to 1

# ==================
# === Main  Loop ===
# ==================
												
main_L1:

				li	  $13, PORT_PBTNS
				lw	  $21, 0($13)

				and	  $22, $21, 0x2				// center button push detected, go to menu
				beq	  $22, 0x2, dis_en

				beq $0,$0,	main_L1				#	} // end - main while loop
				nop

addr_push_btn:

				lb	$9,(CURRENT_STATE_CAM)	 					// Read CURRENT_STATE
				beq $9,SM_ENABLE_DISABLE,dis_en_next			// determine the next state
				beq $9,SM_BLUE_GREEN,blue_green_next
				beq $9,SM_IMG,img_sel_next
				j main_L1										// no state match, exit menu

dis_en_next:

				and $22, $21, 0x10
				beq $22, 0x10, blue_green		// up pressed go to blue_green state

				and $22, $21, 0x8
				beq $22, 0x8, img_sel			// down pressed go to img_sel state

				and $22, $21, 0x4
				beq $22, 0x4, reset_cam			// left pressed, exit menu

				and $22, $21, 0x1
				beq $22, 0x1, set_dis_en		// right pressed

				j 	menu_loop					// any other combination pressed, go back to loop and wait for another push button

blue_green_next:

				and $22, $21, 0x10
				beq $22, 0x10, img_sel			// up pressed go to img_sel state

				and $22, $21, 0x8
				beq $22, 0x8, dis_en			// down pressed go to dis_en state

				and $22, $21, 0x4
				beq $22, 0x4, reset_cam			// left pressed, exit menu

				and $22, $21, 0x1
				beq $22, 0x1, set_blue_green	// right pressed

				j 	menu_loop					// any other combination pressed, go back to loop and wait for another push button

img_sel_next:

				and $22, $21, 0x10
				beq $22, 0x10, dis_en			// up pressed go to dis_en state

				and $22, $21, 0x8
				beq $22, 0x8, blue_green	    // down pressed go to blue_green state

				and $22, $21, 0x4
				beq $22, 0x4, reset_cam			// left pressed, exit menu

				and $22, $21, 0x1
				beq $22, 0x1, set_img			// right pressed

				j 	menu_loop					// any other combination pressed, go back to loop and wait for another push button

menu_loop:
				li  $13, PORT_PBTNS
				lw	$21, 0($13)					// Read buttons
				beq $21, $0, menu_loop			// no push_buttons, stay in loop
				j	addr_push_btn				// button push, address the button push

dis_en:
				addi $9,$0,SM_ENABLE_DISABLE
				sb $9, CURRENT_STATE_CAM
				jal wr_alldigits				// write everything to 7 sagments

				j 	menu_loop					// go to menu loop and wait for another push button

set_dis_en:
				beq $23, 0xE1C, disable_cam		// if cam enable, go disable it
				addi $23, $0, 0xE1C				// camera disabled already, enable it
				j dis_en
disable_cam:
				add $23, $0, 0xd18				// camera enable, disable it
				j dis_en

blue_green:
				addi $9,$0,SM_BLUE_GREEN
				sb $9, CURRENT_STATE_CAM
				jal wr_alldigits				// write everything to 7 sagments


				j menu_loop						// go to menu loop and wait for another push button

set_blue_green:

				beq $20, 0xb1A, make_green
				add $20, $0, 0xb1A				// change from green to blue
				j blue_green

make_green:
				addi $20, $0, 0x1F1B			// change from blue to green
				j blue_green

img_sel:
				addi $9,$0,SM_IMG
				sb $9, CURRENT_STATE_CAM
				jal wr_alldigits				// write everything to 7 sagments

				j menu_loop						// stay here, no button push

set_img:
				beq $19, 0x1, make_two
				beq $19, 0x2, make_three
				beq $19, 0x3, make_four
make_two:
				addi $19, $0, 0x2			    // change to second image
				j img_sel
make_three:
				addi $19, $0, 0x3				 // change to third image
				j img_sel
make_four:
				addi $19, $0, 0x4				 // change to fourth image
				j img_sel
make_one:
				addi $19, $0, 0x1				 // change to first image
				j img_sel
reset_cam:
				addi $9,$0,SM_RESET_CAM
				sb $9, CURRENT_STATE_CAM
				jal wr_alldigits
				j main_L1



wr_alldigits:

				li 	$18, PORT_SEVENSEG_HGH
				li 	$2, PORT_SEVENSEG_EN
				li 	$25, 0xEC					// Enable 5th display segments
				sw	$25, 0($2)
				li 	$2, PORT_SEVENSEG_LOW

				beq $9, SM_RESET_CAM, turn_off_disp			// if in reset state, turn off all seven-sagments, we are leaving the menu state
				beq $9, SM_ENABLE_DISABLE, disp_en_dis
				beq $9, SM_BLUE_GREEN, disp_blu_gr
				beq $9, SM_IMG, disp_img
disp_en_dis:
				sw	$23, 0($2)					// Write to the lower 7 segment displays
				addi $25, $0, 0x1
				sw	$25, 0($18)
				nop
				j skip_turn_off
disp_blu_gr:
				sw	$20, 0($2)					// Write to the lower 7 segment displays
				addi $25, $0, 0x2
				sw	$25, 0($18)
				j skip_turn_off
disp_img:
				sw	$19, 0($2)					// Write to the lower 7 segment displays
				addi $25, $0, 0x3
				sw	$25, 0($18)
				nop
				j skip_turn_off
turn_off_disp:
				li 	$25, 0xFF					// turnoff seven sagment
				li 	$2, PORT_SEVENSEG_EN
				sw	$25, 0($2)
				nop
skip_turn_off:
				jr 	$ra
				nop

