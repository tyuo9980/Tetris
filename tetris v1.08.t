%By Peter Li
%
% BUG: rotate merging along wall
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.08 - 5/4/11
% - Implemented hold feature
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.07 - 4/24/11
% - Working skip intro option
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.06 - 4/23/11
% - Various rotation bug fixes
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.05 - 4/22/11
% - Added skip intro option
% - Added non-runtime error quit
% - Various bug fixes
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.04 - 4/20/11
% - Fixed block merging during rotation
% - Control changes
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.03 - 4/2/11
% - Bubblesorted leaderboards
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.02 - 3/31/11
% - Implemented preview feature
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.01 - 3/29/11
% - Fixed piece bounce back
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% v1.0 - 3/28/11
% - Initial release
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

var shape : int                                                             %game vars
var tempshape : int
var heldshape : int
var nextshape : int
var totalpieces : int
var input : string
var name : string
var delay1 : int
var score : int
var lines : int
var combo : int
var ptimenow, ptimelast : int
var timenow, timelast : int
var timer : int
var counter : int
var setting : string

var back2menu : boolean
var stopped : boolean
var stacked : boolean
var music : boolean
var preventmerge : boolean
var quitgame : boolean
var grotate : boolean := true
var shapeheld : boolean := false

var cols : array - 1 .. 12, -1 .. 28 of int                                 %saves colour data
var grid : array - 1 .. 12, -1 .. 28 of boolean                             %keeps track of moving pieces
var oldgrid : array - 1 .. 12, -1 .. 28 of boolean                          %keeps track of stopped pieces
var boxx : array 0 .. 11 of int                                             %grid to actual coord values
var boxy : array 0 .. 28 of int
var sx : array 1 .. 4 of int                                                %shape coords
var sy : array 1 .. 4 of int
var sxt : array 1 .. 4 of int                                               %temporary rotational storage
var syt : array 1 .. 4 of int
var pivotx : int                                                            %pivot points
var pivoty : int

var colr : int                                                              %colour of pieces
var p1, p2, p3, p4, p5, p6, p7 : int                                        %tally of pieces

var key : string (1)                                                        %input vars
var chars : array char of boolean

var text : string                                                           %scoreboard vars
var fnum : int
var names : array 0 .. 21 of string
var line : array 0 .. 21 of int
var swap : boolean

open : fnum, "settings.ini", get                                            %reads settings
get : fnum, text : *
close : fnum

if text = "playintro = true" then                                           %selects toggle display
    setting := "On"
elsif text = "playintro = false" then
    setting := "Off"
end if

randint (nextshape, 1, 7)
fnum := 1
quitgame := false                                                           %default

View.Set ("graphics:800;600, nocursor, offscreenonly, nobuttonbar")

process musicdrop                                                           %music processes
    Music.PlayFile ("drop.wav")
end musicdrop

process musicturn
    Music.PlayFile ("turn.wav")
end musicturn

process musicline
    Music.PlayFile ("line.wav")
end musicline

process musiclose
    Music.PlayFile ("lose.wav")
end musiclose

process musicintro
    Music.PlayFile ("intro.wav")
end musicintro

process mainmusic
    Music.PlayFileLoop ("tetris.mp3")
end mainmusic

procedure setmap                                                            %creates background
    Draw.FillBox (1, 1, 800, 600, black)
    colourback (black)
    colour (white)
end setmap

procedure intro
    fork musicintro

    for a : 16 .. 31
	locatexy (230, 300)
	color (a)
	put "This pro tetris game is by..."
	View.Update
	delay (50)
    end for

    for decreasing b : 31 .. 16
	locatexy (230, 300)
	color (b)
	put "This pro tetris game is by..."
	View.Update
	delay (50)
    end for

    for c : 16 .. 31
	locatexy (435, 300)
	color (c)
	put "Peter Li"
	View.Update
	delay (100)
    end for

    delay (1250)
end intro

procedure reset                                                             %variable reset
    cls
    setmap

    back2menu := false
    stopped := true
    music := false
    preventmerge := false
    score := 0
    timer := 0
    lines := 0
    combo := 0
    counter := 0
    totalpieces := 0
    p1 := 0
    p2 := 0
    p3 := 0
    p4 := 0
    p5 := 0
    p6 := 0
    p7 := 0

    for x : 1 .. 4
	sx (x) := 0
	sy (x) := 0
    end for

    for x : -1 .. 12
	for y : -1 .. 28
	    grid (x, y) := false
	end for
    end for

    for x : -1 .. 12
	for y : -1 .. 28
	    oldgrid (x, y) := false
	end for
    end for
end reset

procedure savefile                                                          %saves score if game is over
    Music.PlayFileStop
    fork musiclose

    View.Set ("graphics:800;600, nobuttonbar, nocursor, nooffscreenonly")
    cls
    locatexy (maxx div 2 - 25, maxy div 2)
    put "GAME OVER"
    locatexy (375, 500)
    put "Enter name"
    locatexy (375, 475)
    get name : *

    open : fnum, "score.txt", get, mod                                      %retrieves old data
    for x : 1 .. 20
	exit when eof (fnum)
	get : fnum, names (x)
	get : fnum, line (x)
    end for
    close : fnum

    names (21) := name                                                       %temp storage
    line (21) := lines

    for x : 1 .. 20                                                          %bubblesort
	swap := false
	for y : 1 .. 21 - x
	    if line (y) < line (y + 1) then
		line (0) := line (y)
		names (0) := names (y)
		line (y) := line (y + 1)
		names (y) := names (y + 1)
		line (y + 1) := line (0)
		names (y + 1) := names (0)
		swap := true
	    end if
	end for
	exit when swap = false
    end for

    open : fnum, "score.txt", put                                           %saves sorted data
    for x : 1 .. 20
	put : fnum, names (x)
	put : fnum, line (x)
    end for
    close : fnum

    View.Set ("graphics:800;600, nobuttonbar, nocursor, offscreenonly")

    loop                                                                    %prompts for retry
	cls
	setmap
	Input.KeyDown (chars)
	put "Do you want to retry? (Y/N)"
	locatexy (340, 400)
	put "Your score: ", score
	locatexy (maxx div 2 - 25, maxy div 2)
	put "GAME OVER"
	if chars ('y') or chars ('Y') then
	    back2menu := true
	    exit
	elsif chars ('n') or chars ('N') then
	    quitgame := true
	    exit
	end if

	View.Update
    end loop
end savefile

procedure setgrid
    for x : 0 .. 11                                                         %applies grid system
	boxx (x) := 280 + (20 * x)
    end for

    for y : 0 .. 28
	boxy (y) := 10 + (20 * y)
    end for

    for bug : 0 .. 1
	boxx (bug) := 300
	boxy (bug) := 30
    end for
end setgrid

procedure clgrid                                                            %resets grid to false
    for x : 1 .. 10
	for y : 0 .. 26
	    grid (x, y) := false
	end for
    end for
end clgrid

procedure drawgrid                                                          %draws grid lines
    for vertical : 0 .. 10
	Draw.Line (300 + (20 * vertical), 30, 300 + (20 * vertical), 550, white)
    end for

    for horizontal : 0 .. 26
	Draw.Line (300, 30 + (20 * horizontal), 500, 30 + (20 * horizontal), white)
    end for
end drawgrid

procedure savecoords                                                        %stores coords after block stops
    for xy : 1 .. 4
	cols (sx (xy), sy (xy)) := colr
	oldgrid (sx (xy), sy (xy)) := true
    end for
end savecoords

procedure stack                                                             %check if there is a piece underneath
    if totalpieces > 1 then
	for x : 1 .. 10
	    for y : 1 .. 26
		if grid (x, y) and oldgrid (x, y - 1) then
		    stopped := true
		    stacked := true
		    savecoords
		    exit
		end if
	    end for
	end for
    end if
end stack

procedure collide                                                           %checks for collision
    for y : 1 .. 4                                                          %hits bottom
	if sy (y) = 1 then
	    stopped := true
	    savecoords
	    exit
	end if
    end for

    for xy : 1 .. 4                                                         %hits top then gameover
	if back2menu or quitgame then
	    exit
	end if

	if oldgrid (sx (xy), 26) then
	    savefile
	    exit
	end if
    end for
end collide

procedure spawnpiece
    shape := nextshape
    randint (nextshape, 1, 7)
    
    if totalpieces = 1 then
	randint (shape, 1, 7)
    end if
    
    stopped := false
    stacked := false
    
    case shape of                                                           %sets spawn coordinates
	label 1 :                                                           %square
	    p1 += 1
	    sx (1) := 4
	    sx (2) := 4
	    sx (3) := 5
	    sx (4) := 5
	    sy (1) := 26
	    sy (2) := 25
	    sy (3) := 26
	    sy (4) := 25
	label 2 :                                                           %bar
	    p2 += 1
	    sx (1) := 4
	    sx (2) := 5
	    sx (3) := 6
	    sx (4) := 7
	    sy (1) := 26
	    sy (2) := 26
	    sy (3) := 26
	    sy (4) := 26
	label 3 :                                                           %T
	    p3 += 1
	    sx (1) := 4
	    sx (2) := 5
	    sx (3) := 5
	    sx (4) := 6
	    sy (1) := 25
	    sy (2) := 26
	    sy (3) := 25
	    sy (4) := 25
	label 4 :                                                           %Z
	    p4 += 1
	    sx (1) := 4
	    sx (2) := 5
	    sx (3) := 5
	    sx (4) := 6
	    sy (1) := 26
	    sy (2) := 26
	    sy (3) := 25
	    sy (4) := 25
	label 5 :                                                           %reverse Z
	    p5 += 1
	    sx (1) := 4
	    sx (2) := 5
	    sx (3) := 5
	    sx (4) := 6
	    sy (1) := 25
	    sy (2) := 26
	    sy (3) := 25
	    sy (4) := 26
	label 6 :                                                           %L
	    p6 += 1
	    sx (1) := 4
	    sx (2) := 5
	    sx (3) := 6
	    sx (4) := 6
	    sy (1) := 25
	    sy (2) := 25
	    sy (3) := 26
	    sy (4) := 25
	label 7 :                                                           %reverse L
	    p7 += 1
	    sx (1) := 4
	    sx (2) := 4
	    sx (3) := 5
	    sx (4) := 6
	    sy (1) := 26
	    sy (2) := 25
	    sy (3) := 25
	    sy (4) := 25
    end case
end spawnpiece

procedure drawpiece
    if stopped then
	totalpieces += 1
	spawnpiece
    end if

    case shape of
	label 1 :                                                           %box:
	    colr := 14                                                      %yellow
	label 2 :                                                           %bar:
	    colr := 11                                                      %cyan
	    pivotx := sx (2)                                                %sets pivot coords
	    pivoty := sy (2)
	label 3 :                                                           %T:
	    colr := 34                                                      %violet
	    pivotx := sx (2)
	    pivoty := sy (2)
	label 4 :                                                           %Z:
	    colr := 12                                                      %red
	    pivotx := sx (2)
	    pivoty := sy (2)
	label 5 :                                                           %rZ:
	    colr := 10                                                      %green
	    pivotx := sx (2)
	    pivoty := sy (2)
	label 6 :                                                           %L:
	    colr := 42                                                      %orange
	    pivotx := sx (2)
	    pivoty := sy (2)
	label 7 :                                                           %rL:
	    colr := 55                                                      %blue
	    pivotx := sx (2)
	    pivoty := sy (2)
    end case

    for draw : 1 .. 4                                                       %sets piece to true
	grid (sx (draw), sy (draw)) := true
    end for

    for x : 1 .. 10                                                         %draws if true
	for y : 1 .. 26
	    if grid (x, y) then
		Draw.FillBox (boxx (x) + 1, boxy (y) + 1, boxx (x) + 19, boxy (y) + 19, colr)
	    end if
	end for
    end for
end drawpiece

procedure fullrow                                                           %checks if a row is full
    for col : 1 .. 26
	if oldgrid (1, col) and oldgrid (2, col) and oldgrid (3, col) and oldgrid (4, col) and oldgrid (5, col) and oldgrid (6, col) and oldgrid (7, col)
		and oldgrid (8, col) and oldgrid (9, col) and oldgrid (10, col) then

	    for row : 1 .. 10
		oldgrid (row, col) := false
	    end for

	    for gy : col + 1 .. 26                                          %drops everything above down
		for gx : 1 .. 10
		    if oldgrid (gx, gy) then
			oldgrid (gx, gy) := false
			oldgrid (gx, gy - 1) := true
			cols (gx, gy - 1) := cols (gx, gy)
		    end if
		end for
	    end for

	    lines += 1
	    score := lines * 1337

	    fork musicline
	end if
    end for
end fullrow

procedure drawoldpiece                                                      %draws if true
    for x : 1 .. 10
	for y : 1 .. 26
	    if oldgrid (x, y) then
		Draw.FillBox (boxx (x) + 1, boxy (y) + 1, boxx (x) + 19, boxy (y) + 19, cols (x, y))
	    end if
	end for
    end for
end drawoldpiece

procedure holdpiece
    if shapeheld then
	tempshape := heldshape
	heldshape := shape
	shape := tempshape
	spawnpiece
    else
	shapeheld := true
	heldshape := shape
	spawnpiece
    end if
end holdpiece

procedure rotatecheck
    for draw : 1 .. 4                                                       %sets piece to true
	grid (sxt (draw), syt (draw)) := true
    end for

    if totalpieces > 1 then
	for checkcollide : 1 .. 4                                           %checks if piece is blocked
	    if grid (sxt (checkcollide), syt (checkcollide)) and oldgrid (sxt (checkcollide), syt (checkcollide)) then
		grotate := false
	    end if
	end for
    end if

    for checkcollide : 1 .. 4                                               %checks if piece goes under grid
	if syt (checkcollide) < 1 then
	    grotate := false
	end if
    end for

    if grotate then                                                         %rotate if it passes rotation check
	for checkright : 1 .. 4                                             %keeps right side in bounds
	    if sxt (checkright) > 10 then
		for moveleft : 1 .. 4
		    sxt (moveleft) -= 1
		end for
	    end if
	end for

	for checkleft : 1 .. 4                                              %keeps left side in bounds
	    if sxt (checkleft) < 1 then
		for moveright : 1 .. 4
		    sxt (moveright) += 1
		end for
	    end if
	end for

	for save : 1 .. 4                                                   %saves all coords
	    sx (save) := sxt (save)
	    sy (save) := syt (save)
	end for
    end if
end rotatecheck

procedure rotatecc
    grotate := true

    if shape > 1 then                                                       %rotates all shapes except for square
	for turn : 1 .. 4
	    sxt (turn) := pivotx + (pivoty - sy (turn))
	    syt (turn) := pivoty - (pivotx - sx (turn))
	end for

	rotatecheck
    end if
end rotatecc

procedure rotate
    grotate := true

    if shape > 1 then                                                       %rotates all shapes except for square
	for turn : 1 .. 4
	    sxt (turn) := pivotx - (pivoty - sy (turn))
	    syt (turn) := pivoty + (pivotx - sx (turn))
	end for

	rotatecheck
    end if
end rotate

procedure drawstats                                                         %shows stats
    locatexy (0, 500)
    put "Square: ", p1
    put "Bar:    ", p2
    put "T:      ", p3
    put "Z:      ", p4
    put "rZ:     ", p5
    put "L:      ", p6
    put "rL:     ", p7
    put "Total:  ", totalpieces
    put ""
    put "Lines:  ", lines
    put ""
    put ""
    put "Move Left:             LeftArrow"
    put "Move Right:            RightArrow"
    put "Move Down:             DownArrow"
    put "Rotate:                X"
    put "RotateCC:              Z"
    %put "Hold:                  Z"
    put "Quick Drop:            Spacebar"

    locatexy (20, 585)                                                      %scoreboard
    put "Press 0 to return to menu"
    locatexy (20, 575)
    put "Press P to pause"
    locatexy (20, 565)
    put "Press M to toggle music"
    locatexy (375, 585)
    put "Time: ", timer
    locatexy (650, 585)
    put "Score: ", score
    /*locatexy (185, 450)
    put "Held:"
    
    locatexy (185, 450)
    if shapeheld then
	case heldshape of                                                   %held piece
	    label 1 :                                                       %draws shapes
		put "Held: Square"
		Draw.FillBox (200, 400, 220, 420, 14)
		Draw.FillBox (200, 380, 220, 400, 14)
		Draw.FillBox (220, 400, 240, 420, 14)
		Draw.FillBox (220, 380, 240, 400, 14)
		Draw.Box (200, 400, 220, 420, white)
		Draw.Box (200, 380, 220, 400, white)
		Draw.Box (220, 400, 240, 420, white)
		Draw.Box (220, 380, 240, 400, white)
	    label 2 :
		put "Held: Bar"
		Draw.FillBox (180, 400, 200, 420, 11)
		Draw.FillBox (200, 400, 220, 420, 11)
		Draw.FillBox (220, 400, 240, 420, 11)
		Draw.FillBox (240, 400, 260, 420, 11)
		Draw.Box (180, 400, 200, 420, white)
		Draw.Box (200, 400, 220, 420, white)
		Draw.Box (220, 400, 240, 420, white)
		Draw.Box (240, 400, 260, 420, white)
	    label 3 :
		put "Held: T"
		Draw.FillBox (180, 380, 200, 400, 34)
		Draw.FillBox (200, 380, 220, 400, 34)
		Draw.FillBox (220, 380, 240, 400, 34)
		Draw.FillBox (200, 400, 220, 420, 34)
		Draw.Box (180, 380, 200, 400, white)
		Draw.Box (200, 380, 220, 400, white)
		Draw.Box (220, 380, 240, 400, white)
		Draw.Box (200, 400, 220, 420, white)
	    label 4 :
		put "Held: Z"
		Draw.FillBox (180, 400, 200, 420, 12)
		Draw.FillBox (200, 400, 220, 420, 12)
		Draw.FillBox (200, 380, 220, 400, 12)
		Draw.FillBox (220, 380, 240, 400, 12)
		Draw.Box (180, 400, 200, 420, white)
		Draw.Box (200, 400, 220, 420, white)
		Draw.Box (200, 380, 220, 400, white)
		Draw.Box (220, 380, 240, 400, white)
	    label 5 :
		put "Held: rZ"
		Draw.FillBox (180, 380, 200, 400, 10)
		Draw.FillBox (200, 380, 220, 400, 10)
		Draw.FillBox (200, 400, 220, 420, 10)
		Draw.FillBox (220, 400, 240, 420, 10)
		Draw.Box (180, 380, 200, 400, white)
		Draw.Box (200, 380, 220, 400, white)
		Draw.Box (200, 400, 220, 420, white)
		Draw.Box (220, 400, 240, 420, white)
	    label 6 :
		put "Held: L"
		Draw.FillBox (180, 380, 200, 400, 42)
		Draw.FillBox (200, 380, 220, 400, 42)
		Draw.FillBox (220, 380, 240, 400, 42)
		Draw.FillBox (220, 400, 240, 420, 42)
		Draw.Box (180, 380, 200, 400, white)
		Draw.Box (200, 380, 220, 400, white)
		Draw.Box (220, 380, 240, 400, white)
		Draw.Box (220, 400, 240, 420, white)
	    label 7 :
		put "Held: rL"
		Draw.FillBox (180, 400, 200, 420, 55)
		Draw.FillBox (180, 380, 200, 400, 55)
		Draw.FillBox (200, 380, 220, 400, 55)
		Draw.FillBox (220, 380, 240, 400, 55)
		Draw.Box (180, 400, 200, 420, white)
		Draw.Box (180, 380, 200, 400, white)
		Draw.Box (200, 380, 220, 400, white)
		Draw.Box (220, 380, 240, 400, white)
	end case
    end if*/

    locatexy (585, 450)
    case nextshape of                                                       %next piece preview
	label 1 :                                                           %draws shapes
	    put "Next: Square"
	    Draw.FillBox (600, 400, 620, 420, 14)
	    Draw.FillBox (600, 380, 620, 400, 14)
	    Draw.FillBox (620, 400, 640, 420, 14)
	    Draw.FillBox (620, 380, 640, 400, 14)
	    Draw.Box (600, 400, 620, 420, white)
	    Draw.Box (600, 380, 620, 400, white)
	    Draw.Box (620, 400, 640, 420, white)
	    Draw.Box (620, 380, 640, 400, white)
	label 2 :
	    put "Next: Bar"
	    Draw.FillBox (580, 400, 600, 420, 11)
	    Draw.FillBox (600, 400, 620, 420, 11)
	    Draw.FillBox (620, 400, 640, 420, 11)
	    Draw.FillBox (640, 400, 660, 420, 11)
	    Draw.Box (580, 400, 600, 420, white)
	    Draw.Box (600, 400, 620, 420, white)
	    Draw.Box (620, 400, 640, 420, white)
	    Draw.Box (640, 400, 660, 420, white)
	label 3 :
	    put "Next: T"
	    Draw.FillBox (580, 380, 600, 400, 34)
	    Draw.FillBox (600, 380, 620, 400, 34)
	    Draw.FillBox (620, 380, 640, 400, 34)
	    Draw.FillBox (600, 400, 620, 420, 34)
	    Draw.Box (580, 380, 600, 400, white)
	    Draw.Box (600, 380, 620, 400, white)
	    Draw.Box (620, 380, 640, 400, white)
	    Draw.Box (600, 400, 620, 420, white)
	label 4 :
	    put "Next: Z"
	    Draw.FillBox (580, 400, 600, 420, 12)
	    Draw.FillBox (600, 400, 620, 420, 12)
	    Draw.FillBox (600, 380, 620, 400, 12)
	    Draw.FillBox (620, 380, 640, 400, 12)
	    Draw.Box (580, 400, 600, 420, white)
	    Draw.Box (600, 400, 620, 420, white)
	    Draw.Box (600, 380, 620, 400, white)
	    Draw.Box (620, 380, 640, 400, white)
	label 5 :
	    put "Next: rZ"
	    Draw.FillBox (580, 380, 600, 400, 10)
	    Draw.FillBox (600, 380, 620, 400, 10)
	    Draw.FillBox (600, 400, 620, 420, 10)
	    Draw.FillBox (620, 400, 640, 420, 10)
	    Draw.Box (580, 380, 600, 400, white)
	    Draw.Box (600, 380, 620, 400, white)
	    Draw.Box (600, 400, 620, 420, white)
	    Draw.Box (620, 400, 640, 420, white)
	label 6 :
	    put "Next: L"
	    Draw.FillBox (580, 380, 600, 400, 42)
	    Draw.FillBox (600, 380, 620, 400, 42)
	    Draw.FillBox (620, 380, 640, 400, 42)
	    Draw.FillBox (620, 400, 640, 420, 42)
	    Draw.Box (580, 380, 600, 400, white)
	    Draw.Box (600, 380, 620, 400, white)
	    Draw.Box (620, 380, 640, 400, white)
	    Draw.Box (620, 400, 640, 420, white)
	label 7 :
	    put "Next: rL"
	    Draw.FillBox (580, 400, 600, 420, 55)
	    Draw.FillBox (580, 380, 600, 400, 55)
	    Draw.FillBox (600, 380, 620, 400, 55)
	    Draw.FillBox (620, 380, 640, 400, 55)
	    Draw.Box (580, 400, 600, 420, white)
	    Draw.Box (580, 380, 600, 400, white)
	    Draw.Box (600, 380, 620, 400, white)
	    Draw.Box (620, 380, 640, 400, white)
    end case
end drawstats

procedure leaderboard                                                       %draws leaderboard
    loop
	cls
	put "[0] Return"
	put ""
	View.Update

	open : fnum, "score.txt", get, mod                                  %retrieves data
	for x : 1 .. 20
	    exit when eof (fnum)
	    get : fnum, names (x)
	    get : fnum, line (x)
	end for
	close : fnum

	for x : 1 .. 20
	    put names (x) : 20, "   ", line (x)
	end for

	View.Update

	getch (key)
	if key = "0" then
	    exit
	end if
    end loop
end leaderboard

procedure getinput
    if hasch then
	getch (key)
	if key = "x" or key = "X" then
	    rotate                                                          %rotates clockwise
	    fork musicturn
	elsif key = "Z" or key = "Z" then
	    rotatecc                                                        %rotates counter clockwise
	    fork musicturn
	%elsif key = "z" or key = "Z" then
	%    holdpiece
	%    fork musicturn
	elsif key = chr (208) then                                          %down arrow key
	    for y : 1 .. 4                                                  %moves down
		if sy (y) = 1 then                                          %checks if it hits wall
		    sy (1) += 1
		    sy (2) += 1
		    sy (3) += 1
		    sy (4) += 1
		end if
	    end for

	    for x : 1 .. 10                                                 %checks for collision with previous pieces
		for y : 2 .. 26
		    if grid (x, y) and oldgrid (x, y - 1) then
			sy (1) += 1
			sy (2) += 1
			sy (3) += 1
			sy (4) += 1
			preventmerge := true
			exit
		    end if
		end for
		if preventmerge then
		    preventmerge := false
		    exit
		end if
	    end for

	    for y : 1 .. 4
		sy (y) -= 1
	    end for
	elsif key = chr (203) then                                          %left arrow key
	    for x : 1 .. 4                                                  %moves left
		if sx (x) = 1 then                                          %checks if it hits wall
		    sx (1) += 1
		    sx (2) += 1
		    sx (3) += 1
		    sx (4) += 1
		end if
	    end for

	    for x : 2 .. 10                                                 %checks for collision with previous pieces
		for y : 1 .. 26
		    if grid (x, y) and oldgrid (x - 1, y) then
			sx (1) += 1
			sx (2) += 1
			sx (3) += 1
			sx (4) += 1
			preventmerge := true
			exit
		    end if
		end for
		if preventmerge then
		    preventmerge := false
		    exit
		end if
	    end for

	    for x : 1 .. 4
		sx (x) -= 1
	    end for

	    timelast := timenow
	elsif key = chr (205) then                                          %right arrow key
	    for x : 1 .. 4                                                  %moves right
		if sx (x) = 10 then
		    sx (1) -= 1
		    sx (2) -= 1
		    sx (3) -= 1
		    sx (4) -= 1
		end if
	    end for

	    for x : 1 .. 9                                                  %checks for collision with previous pieces
		for y : 1 .. 26
		    if grid (x, y) and oldgrid (x + 1, y) then
			sx (1) -= 1
			sx (2) -= 1
			sx (3) -= 1
			sx (4) -= 1
			preventmerge := true
			exit
		    end if
		end for
		if preventmerge then
		    preventmerge := false
		    exit
		end if
	    end for

	    for x : 1 .. 4
		sx (x) += 1
	    end for
	elsif key = " " then                                                %quick drop
	    fork musicdrop
	    loop
		exit when
		    stopped or stacked or back2menu or quitgame
		collide
		stack
		exit when
		    stopped or stacked or back2menu or quitgame
		for y : 1 .. 4
		    sy (y) -= 1
		    grid (sx (y), sy (y)) := true
		end for
	    end loop
	elsif key = "p" or key = "P" then                                   %pause
	    cls
	    put "Enter any key to resume"
	    View.Update
	    getch (key)
	    View.Update
	elsif key = "m" or key = "M" then
	    if not music then
		Music.PlayFileStop
		music := true
	    elsif music then
		music := false
		fork mainmusic
	    end if
	elsif key = "0" then                                                %exit
	    loop
		cls
		put "Are you sure you want to quit? (Y/N)"
		Input.KeyDown (chars)
		if chars ('y') or chars ('Y') then
		    back2menu := true
		    exit
		elsif chars ('n') or chars ('N') then
		    exit
		end if

		View.Update
	    end loop
	end if
    end if
end getinput

procedure calctime                                                          %checks for collision or stack per delay interval
    timenow := Time.Elapsed
    if timenow - timelast >= 1000 then
	timer += 1
	timelast := timenow
    end if

    ptimenow := Time.Elapsed

    if ptimenow - ptimelast >= delay1 then
	collide
	stack
	for y : 1 .. 4
	    exit when back2menu or quitgame
	    sy (y) -= 1
	end for
	ptimelast := ptimenow
    end if
end calctime

procedure endless                                                           %game procedure
    loop
	if back2menu or quitgame then
	    exit
	end if

	fork mainmusic

	reset
	delay1 := 600

	if back2menu or quitgame then
	    exit
	end if

	timelast := Time.Elapsed
	ptimelast := Time.Elapsed

	loop

	    if back2menu or quitgame then
		exit
	    end if

	    cls
	    clgrid
	    drawstats
	    drawgrid
	    drawpiece
	    drawoldpiece
	    fullrow
	    getinput
	    calctime

	    if back2menu or quitgame then
		exit
	    end if

	    if lines > 10 and lines <= 20 then
		delay1 := 500
	    elsif lines > 21 and lines <= 30 then
		delay1 := 400
	    elsif lines > 31 and lines <= 40 then
		delay1 := 300
	    elsif lines > 40 then
		delay1 := 175
	    end if

	    View.Update

	end loop
    end loop
end endless

setmap
if setting = "On" then
    intro
end if
setgrid

loop                                                                        %main program/menu
    if quitgame then
	exit
    end if

    Music.PlayFileStop
    reset
    cls
    put "[1] Start Game"
    put "[2] Leaderboard"
    put "[3] Toggle Intro: ", setting
    put ""
    put "[0] Exit"

    View.Update

    getch (key)
    if key = "1" then
	endless
    elsif key = "2" then
	cls
	setmap
	leaderboard
    elsif key = "3" then
	if setting = "On" then
	    setting := "Off"
	    open : fnum, "settings.ini", put
	    put : fnum, "playintro = false"
	    close : fnum
	else
	    setting := "On"
	    open : fnum, "settings.ini", put
	    put : fnum, "playintro = true"
	    close : fnum
	end if
    elsif key = "0" then
	loop
	    cls
	    put "Are you sure you want to quit? (Y/N)"
	    Input.KeyDown (chars)
	    if chars ('y') or chars ('Y') then
		quitgame := true
		exit
	    elsif chars ('n') or chars ('N') then
		exit
	    end if

	    View.Update

	end loop
    end if
end loop
