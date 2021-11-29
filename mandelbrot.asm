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
zre: dd 0
zim: dd 0

; Nombre Complexe C
cre: dd 0
cim: dd 0

; Coordonees Pour Dessin
x: dd 0
y: dd 0
i: db 0

; Coordonees de la fractale
x1: dd -2.1
x2: dd 0.6
y1: dd -1.2
y2: dd 1.2

; Calculs de flottants:

zero: dd 0.0
deux: dd 2.0
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

;définir image_x = (x2 - x1) * zoom
;définir image_y = (y2 - y1) * zoom

movss xmm0, [x2]
movss xmm1, [y2]

movss xmm3, [x1]
movss xmm4, [y1]

; xmm0 = x2
; xmm1 = y2
; xmm3 = x1
; xmm4 = y1

subss xmm0, xmm3
subss xmm1, xmm4
; xmm0 = x2-x1
; xmm1 = y2-y1

cvtsi2ss xmm5, [zoom]
; xmm5 = zoom: conversion de zoom en float

mulss xmm0, xmm5
mulss xmm1, xmm5
; xmm0 = (x2-x1)*zoom
; xmm1 = (y2-y1)*zoom

cvtss2si r8,xmm0	; largeur (imageX): conversion de xmm0 en entier
cvtss2si r9,xmm1	; hauteur (imageY): conversion de xmm1 en entier

mov qword[imageX], r8
mov qword[imageY], r9

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
    ; cre = x / zoom + x1
    ; cim = y / zoom + y1
    ; TODO (Prio: 100% MAX): Les calculs de CRE/CIM/ZRE/ZIM ne marchent pas
    cvtsi2ss xmm0, [zoom]
    cvtsi2ss xmm1, [x] ; xmm1 = x
    cvtsi2ss xmm2, [y] ; xmm2 = y

    divss xmm1, xmm0 ; xmm1 = x/zoom
    divss xmm2, xmm0 ; xmm1 = y/zoom

    addss xmm1, [x1] ; xmm1 += x1
    addss xmm2, [y1] ; xmm2 += y1

    movss [cre], xmm1 ; cre = x / zoom + x
    movss [cim], xmm1 ; cim = y / zoom + y1

    ; c = cre + cim*i

    movss xmm0, [zero]
    movss [zre], xmm0
    movss [zim], xmm0
    ; z = 0 + 0i

    mov byte[i], 0
    ; iteration = 0
        boucleDessin: ;do
        movss xmm6, [zre] ; xmm6 --> temp = zre

        ; zre = zre*zre - zim*zim + cre

        cvtss2sd xmm0, [zre]
        movsd [sqr], xmm0
        ; sqr[0] = zre après conversion en 64 bits

        mulsd xmm0, [sqr]
        movsd [sqr], xmm0
        ; sqr[0] = zre²

        cvtss2sd xmm0, [zim]
        movsd [sqr+QWORD], xmm0
        ; sqr[1] = zim après conversion en 64 bits

        mulsd xmm0, [sqr+QWORD]
        movsd [sqr+QWORD], xmm0
        ; sqr[1] = zim²

        movsd xmm0, [sqr]
        subsd xmm0, [sqr+DWORD]
        ; xmm0 = zre² - zim²
        cvtss2sd xmm1, [cre]
        addsd xmm0, xmm1
        ; xmm0 = zre² - zim² + cre
        cvtsd2ss xmm1, xmm0
        movss [zre], xmm1
        ; zre = zre² - zim² + cre


        ; zim = 2*zim*temp + cim
        mulss xmm6, [deux]
        mulss xmm6, [zim]
        ; xmm6-->temp *= 2*zim
        addss xmm6, [cim]
        ; xmm6 = 2*zim*temp + cim

        movss [zim], xmm6
        ; zim = 2*zim*temp + cim


        inc byte[i] ; i++

        ; xmm5 = zre*zre + zim*zim
         cvtss2sd xmm0, [zre]
         movsd [sqr], xmm0
         ; sqr[0] = zre après conversion en 64 bits

         mulsd xmm0, [sqr]
         movsd [sqr], xmm0

        ; sqr[0] = zre²

        cvtss2sd xmm0, [zim]
        movsd [sqr+QWORD], xmm0
        ; sqr[1] = zim après conversion en 64 bits

        mulsd xmm0, [sqr+QWORD]
        movsd [sqr+QWORD], xmm0
         ; sqr[1] = zim²

        movsd xmm5, [sqr]
        addsd xmm5, [sqr+QWORD]
        ; xmm5 = zre*zre + zim*zim

        ; while zre*zre + zim*zim < 4 and i < maxIter

        ucomisd xmm5, [quatre]
        jae finBoucleDessin
        ; and i < maxIter
        mov r13b, byte[i]
        cmp r13b, byte[maxIter]
        jae finBoucleDessin
        jmp boucleDessin

        finBoucleDessin:
        mov r13b, byte[i]
        cmp r13b, byte[maxIter] ;if i = maxIter
        jne finForEach

    mov r13b, byte[i]
    cmp r13b, byte[maxIter] ;if i = maxIter
    jne finForEach
    ;;; Add Point TODO (Priorite Minimale) : Variation de couleurs
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
    ; Fin Point
    finForEach:
    inc dword[y]
    mov r13,0
    mov r13d, dword[y]
    cmp r13, qword[imageY]
    jb forEachLine
inc dword[x]
mov r13,0
mov r13d, dword[x]
cmp r13, qword[imageX]
jb forEachColumn

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
	