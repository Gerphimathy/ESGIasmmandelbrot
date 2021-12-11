; external functions from X11 library
extern XOpenDisplay
extern XDisplayName
extern XCloseDisplay
extern XCreateSimpleWindow
extern XMapWindow
extern XRootWindow
extern XSelectInput
extern XFlush
extern XCreateGC
extern XSetForeground
extern XDrawLine
extern XNextEvent
extern XDrawPoint
; XDrawPoint arguments: (display, d, gc, x, y)

; external functions from stdio library (ld-linux-x86-64.so.2)    
extern printf
extern exit

%define	StructureNotifyMask	131072
%define KeyPressMask		1
%define ButtonPressMask		4
%define MapNotify		19
%define KeyPress		2
%define ButtonPress		4
%define Expose			12
%define ConfigureNotify		22
%define CreateNotify 16
%define QWORD	8
%define DWORD	4
%define WORD	2
%define BYTE	1

global main

section .bss
display_name:	resq	1
screen:			resd	1
depth:         	resd	1
connection:    	resd	1
width:         	resd	1
height:        	resd	1
window:		resq	1
gc:		resq	1

maxIter: resb 1
sqr: resq 2

zoom: resd 1

; largeur et hauteur
imageX: resq 1
imageY: resq 1

section .data

event:		times	24 dq 0

; Nombre Complexe Z
zre: dq 0
zim: dq 0

; Nombre Complexe C
cre: dq 0
cim: dq 0

; Coordonees Pour Dessin
x: dd 0
y: dd 0
i: db 0

; Coordonees de la fractale
x1: dq -2.1
x2: dq 0.6
y1: dq -1.2
y2: dq 1.2

; Calculs de flottants:

zero: dq 0.0
deux: dq 2.0
quatre: dq 4.0

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
; TODO (Priorité Minimale): Name display
xor     rdi,rdi
call    XOpenDisplay	; Création de display
mov     qword[display_name],rax	; rax=nom du display

; display_name structure
; screen = DefaultScreen(display_name);
mov     rax,qword[display_name]
mov     eax,dword[rax+0xe0]
mov     dword[screen],eax

mov rdi,qword[display_name]
mov esi,dword[screen]
call XRootWindow ;return the root window of the specified screen
mov rbx,rax

mov rdi,qword[display_name]
mov rsi,rbx
mov rdx,10
mov rcx,10

;TODO: Scan for this instead

mov dword[zoom], 100

;;;définir image_x = (x2 - x1) * zoom
;;;définir image_y = (y2 - y1) * zoom

    movsd xmm0, [x2]
    movsd xmm1, [y2]

    movsd xmm3, [x1]
    movsd xmm4, [y1]

    ; xmm0 = x2
    ; xmm1 = y2
    ; xmm3 = x1
    ; xmm4 = y1

    subsd xmm0, xmm3
    subsd xmm1, xmm4
    ; xmm0 = x2-x1
    ; xmm1 = y2-y1

    cvtsi2sd xmm5, [zoom]
    ; xmm5 = zoom: conversion de zoom en float

    mulsd xmm0, xmm5
    mulsd xmm1, xmm5
    ; xmm0 = (x2-x1)*zoom
    ; xmm1 = (y2-y1)*zoom

    cvtsd2si r8,xmm0	; largeur (imageX): conversion de xmm0 en entier
    cvtsd2si r9,xmm1	; hauteur (imageY): conversion de xmm1 en entier

    mov qword[imageX], r8
    mov qword[imageY], r9

;;;définir image_x = (x2 - x1) * zoom
;;;définir image_y = (y2 - y1) * zoom

push 0xFFFFFF	; background  0xRRGGBB
push 0x00FF00
push 1
call XCreateSimpleWindow; crée une sous- fenêtre InputOutput non mappée pour une fenêtre parent spécifiée, renvoie l'ID de fenêtre de la fenêtre créée et oblige le serveur X à générer un événement CreateNotify .
mov qword[window],rax

mov rdi,qword[display_name]
mov rsi,qword[window]
mov rdx,131077 ;131072
call XSelectInput ;  demande que le serveur X rapporte les événements associés au masque d'événement spécifié.

mov rdi,qword[display_name]
mov rsi,qword[window]
call XMapWindow ; mappe la fenêtre et toutes ses sous-fenêtres qui ont eu des demandes de mappage

mov rsi,qword[window]
mov rdx,0
mov rcx,0
call XCreateGC ; crée un contexte graphique et renvoie un GC.
mov qword[gc],rax

mov rdi,qword[display_name]
mov rsi,qword[gc]
mov rdx,0x000000	; Couleur du crayon
call XSetForeground ; Spécifie le premier plan que vous souhaitez définir pour le GC spécifié

boucle: ; boucle de gestion des évènements
mov rdi,qword[display_name]
mov rsi,event
call XNextEvent ; copie le premier événement de la file d'attente d'événements dans la structure XEvent spécifiée , puis le supprime de la file d'attente.

cmp dword[event],ConfigureNotify	; à l'apparition de la fenêtre
je dessin							; on saute au label 'dessin'

cmp dword[event],KeyPress			; Si on appuie sur une touche
je closeDisplay						; on saute au label 'closeDisplay' qui ferme la fenêtre
jmp boucle

;#########################################
;#		DEBUT DE LA ZONE DE DESSIN		 #
;#########################################
dessin:

mov dword[x], 0 ; x = 0
mov dword[y], 0 ; y = 0
mov byte[i], 0 ; i = 0

mov byte[maxIter], 50

forEachColumn: ;for (x = 0; x < width; x++)
    mov dword[y], 0
    forEachLine: ;for (y = 0; y < height; y++)
    ; TODO (Prio: 100% MAX): Les calculs de CRE/CIM/ZRE/ZIM ne marchent pas

    ; Début: Initialisation des valeurs pour la boucle principale

        ; Début:
        ; cre = x / zoom + x1
        ; cim = y / zoom + y1
        ; c = cre + cim*i
            cvtsi2sd xmm0, [zoom]
            cvtsi2sd xmm1, [x] ; xmm1 = x
            cvtsi2sd xmm2, [y] ; xmm2 = y

            divsd xmm1, xmm0 ; xmm1 = x/zoom
            divsd xmm2, xmm0 ; xmm2 = y/zoom

            addsd xmm1, [x1] ; xmm1 += x1
            addsd xmm2, [y1] ; xmm2 += y1

            movsd [cre], xmm1 ; cre = x / zoom + x
            movsd [cim], xmm2 ; cim = y / zoom + y1
        ; Fin:
        ; cre = x / zoom + x1
        ; cim = y / zoom + y1
        ; c = cre + cim*i

        ; Début:
        ; zre = 0
        ; zim = 0
        ; z = 0 + 0i
            movsd xmm0, [zero]
            movsd [zre], xmm0
            movsd [zim], xmm0
        ;Fin:
        ; zre = 0
        ; zim = 0
        ; z = 0 + 0i

        mov byte[i], 0 ; iteration = 0

    ; Fin: Initialisation des valeurs pour la boucle principale


        boucleDessin: ; --> do
        movsd xmm6, [zre] ; xmm6 --> temp = zre

        ; Début: zre = zre*zre - zim*zim + cre

            ; Début: sqr[0] = zre²
                movsd xmm0, [zre]
                movsd [sqr], xmm0; sqr[0] = zre

                mulsd xmm0, [sqr] ; xmm0 = zre²
                movsd [sqr], xmm0 ; sqr[0] <-- xmm0 = zre²
            ; Fin: sqr[0] = zre²

            ; Début: sqr[1] = zim ²
                movsd xmm0, [zim]
                movsd [sqr+QWORD], xmm0 ; sqr[1] = zim

                mulsd xmm0, [sqr+QWORD] ; xmm0 = zim²
                movsd [sqr+QWORD], xmm0 ; sqr[1] <-- xmm0 = zim²
            ; Fin: sqr[1] = zim²

            ; Début: Additions:
                movsd xmm0, [sqr] ; xmm0 <-- sqr[0] = zre²
                subsd xmm0, [sqr+DWORD] ; xmm0 -= sqr[1] <-- zim²
                addsd xmm0, [cre] ; xmm0 += cre
                ; --> xmm0 = zre² - zim² + cre
                movsd [zre], xmm0 ; zre <-- xmm0
            ;Fin: Additions

        ; Fin: zre = zre² - zim² + cre


        ; Début: zim = 2*zim*temp + cim

            mulsd xmm6, [deux] ;xmm6 = temp
            mulsd xmm6, [zim]
            ; xmm6 = temp*2*zim

            addsd xmm6, [cim]
            ; xmm6 = 2*zim*temp + cim

            movsd [zim], xmm6 ; zim <-- xmm6

        ; Fin: zim = 2*zim*temp + cim


        inc byte[i] ; i++

        ; Début: xmm5 = zre*zre + zim*zim

            ; Début: sqr[0] = zre²
                movsd xmm0, [zre]
                movsd [sqr], xmm0; sqr[0] = zre

                mulsd xmm0, [sqr] ; xmm0 = zre²
                movsd [sqr], xmm0 ; sqr[0] <-- xmm0 = zre²
            ; Fin: sqr[0] = zre²

            ; Début: sqr[1] = zim ²
                movsd xmm0, [zim]
                movsd [sqr+QWORD], xmm0 ; sqr[1] = zim

                mulsd xmm0, [sqr+QWORD] ; xmm0 = zim²
                movsd [sqr+QWORD], xmm0 ; sqr[1] <-- xmm0 = zim²
            ; Fin: sqr[1] = zim²

            movsd xmm5, [sqr] ; xmm5 <-- sqr[0] = zre²
            addsd xmm5, [sqr+QWORD] ; xmm5 += zim²
        ; Fin: xmm5 = zre*zre + zim*zim

        ; while (zre*zre + zim*zim < 4 and i < maxIter)
            ; (zre*zre + zim*zim < 4 and i < maxIter) = (!(zre*zre + zim*zim > 4) or !(i > maxIter))

            ucomisd xmm5, [quatre] ; xmm5 > 4.0 ?
            jae finBoucleDessin ; Oui: --> Fin Boucle (les deux conditions doivent être vrai)

            ; and i < maxIter
            mov r13b, byte[i]
            cmp r13b, byte[maxIter] ; r13b(i) > maxIter ?
            jae finBoucleDessin ; Oui: --> Fin Boucle (les deux conditions doivent être vrai)
            jmp boucleDessin ; Non --> Les deux conditions sont vraies, le while continue et on retourne dans la boucle

        ; while zre*zre + zim*zim < 4 and i < maxIter

        finBoucleDessin:
        ; if(i == maxIter)
            ; if (!(i != maxIter))

            mov r13b, byte[i]
            cmp r13b, byte[maxIter] ;if i = maxIter
            jne finForEach
            ; Si la condition n'est pas remplie, ça veut dire qu'on a quitté la boucle car zre*zre + zim*zim > 4
            ; Dans ce cas là on ne dessine pas

        ; if(i == maxIter)

        ; Début: dessin:
            ; TODO (Priorite Minimale) : Variation de couleurs
            ; Point Color
            mov rdi,qword[display_name]
            mov rsi,qword[gc]
            mov edx,0x000000	; Couleur: Noir
            call XSetForeground
            ; Draw Point
            mov rdi,qword[display_name]
            mov rsi,qword[window]
            mov rdx,qword[gc]
            mov ecx,dword[x]	; coordonnée source en x
            mov r8d,dword[y]	; coordonnée source en y
            call XDrawPoint
        ; Fin: dessin:

    finForEach:
    inc dword[y] ; y++
    mov r13,0
    mov r13d, dword[y]
    cmp r13, qword[imageY] ; y < imageY ?
    jb forEachLine ; --> Continues la boucle for y
    ; Sinon:
inc dword[x] ; x ++
mov r13,0
mov r13d, dword[x] ; x < imageX ?
cmp r13, qword[imageX] ; --> Continues la boucle for x
jb forEachColumn; Sinon fin de l'image et du dessin

; ############################
; # FIN DE LA ZONE DE DESSIN #
; ############################
jmp flush

flush:
mov rdi,qword[display_name]
call XFlush ; vide le tampon de sortie.
jmp boucle
mov rax,34
syscall

closeDisplay:
    mov     rax,qword[display_name]
    mov     rdi,rax
    call    XCloseDisplay
    xor	    rdi,rdi
    call    exit
	