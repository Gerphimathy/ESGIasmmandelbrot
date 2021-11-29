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

; Coordonees de la fractale
x1: dd -2.1
x2: dd 0.6
y1: dd -1.2
y2: dd 1.2

; Calculs de flottants:

deux: dd 2.0
quatre: dd 4.0

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


; TODO (Priorité Maximale): Test This
;définir image_x = (x2 - x1) * zoom
;définir image_y = (y2 - y1) * zoom

movss xmm0, dword[x2]
movss xmm1, dword[y2]

movss xmm3, dword[x1]
movss xmm4, dword[y1]

; xmm0 = x2
; xmm1 = y2
; xmm3 = x1
; xmm4 = y1

subsd xmm0, xmm3
subsd xmm1, xmm4
; xmm0 = x2-x1
; xmm1 = y2-y1

cvtsi2ss xmm5, dword[zoom]
; xmm5 = zoom: conversion de zoom en float

mulss xmm0, xmm5
mulss xmm1, xmm5
; xmm0 = (x2-x1)*zoom
; xmm1 = (y2-y1)*zoom

cvtss2si r8,xmm0	; largeur: conversion de xmm0 en entier
cvtss2si r9,xmm1	; hauteur: conversion de xmm1 en entier


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

mov r14d, 0 ; y = 0
mov r15d, 0 ; x = 0

mov byte[maxIter], 50

forEachColumn: ;for (x = 0; x < width; x++)
    mov r14d, 0
    forEachLine: ;for (y = 0; y < height; y++)
    mov rcx, 0
    ; TODO (Priorité Maximale): Replace this so that it's proportional to zoom

    ; cre = x / zoom + x1
    ; cim = y / zoom + y1

    cvtsi2ss xmm0, dword[zoom]
    cvtsi2ss xmm1, r15d ; xmm1 = x
    cvtsi2ss xmm2, r14d ; xmm2 = y

    divss xmm1, xmm0 ; xmm1 = x/zoom
    divss xmm2, xmm0 ; xmm1 = y/zoom

    addss xmm1, x1 ; xmm1 += x1
    addss xmm2, y1 ; xmm2 += y1

    movss dword[cre], xmm1 ; cre = x / zoom + x
    movss dword[cim], xmm1 ; cim = y / zoom + y1

    ; c = cre + cim*i

    movss dword[zre], 0
    movss dword[zim], 0
    ; z = 0 + 0i

    mov r13b, 0
    ; iteration = 0
        boucleDessin: ;do
        mov rcx, 0
        mov xmm6, dword[zre] ; xmm6 --> temp = zre

        ; zre = zre*zre - zim*zim + cre

        cvtss2sd xmm0, dword[zre]
        movsd qword[sqr], xmm0
        ; sqr[0] = zre après conversion en 64 bits

        mulsd xmm0, sqr
        movsd qword[sqr], xmm0
        ; sqr[0] = zre²

        cvtss2sd xmm0, dword[zim]
        movsd qword[sqr+QWORD], xmm0
        ; sqr[1] = zim après conversion en 64 bits

        mulsd xmm0, sqr+QWORD
        movsd qword[sqr+QWORD], xmm0
        ; sqr[1] = zim²

        movsd xmm0, qword[sqr]
        subsd xmm0, qword[sqr+DWORD]
        ; xmm0 = zre² - zim²
        cvtss2sd xmm1, dword[cre]
        addsd xmm0, xmm1
        ; xmm0 = zre² - zim² + cre
        cvtsd2si dword[zre], xmm0
        ; zre = zre² - zim² + cre


        ; zim = 2*zim*temp + cim
        mulss xmm6, deux
        mulss xmm6, zim
        ; xmm6-->temp *= 2*zim
        addss xmm6, cim
        ; xmm6 = 2*zim*temp + cim

        movss dword[zim], xmm6
        ; zim = 2*zim*temp + cim


        inc r13b ; i++

        ; xmm5 = zre*zre + zim*zim
         cvtss2sd xmm0, dword[zre]
         movsd qword[sqr], xmm0
         ; sqr[0] = zre après conversion en 64 bits

         mulsd xmm0, sqr
         movsd qword[sqr], xmm0

        ; sqr[0] = zre²

        cvtss2sd xmm0, dword[zim]
        movsd qword[sqr+QWORD], xmm0
        ; sqr[1] = zim après conversion en 64 bits

        mulsd xmm0, sqr+QWORD
        movsd qword[sqr+QWORD], xmm0
         ; sqr[1] = zim²

        movsd xmm5, qword[sqr]
        addsd xmm5, qword[sqr+QWORD]
        ; xmm5 = zre*zre + zim*zim

        ; while zre*zre + zim*zim < 4 and i < maxIter
        ucomisd xmm5, quatre
        jge finBoucleDessin
        ; and i < maxIter
        cmp r13b, byte[maxIter]
        jae finBoucleDessin
        jmp boucleDessin

        finBoucleDessin:
        cmp r13b, byte[maxIter] ;if i = maxIter
        jne finForEach

    cmp r13b, byte[maxIter] ;if i = maxIter
    jne finForEach
    ;;; Add Point
    ; Point Color
    mov rdi,qword[display_name]
    mov rsi,qword[gc]
    mov edx,0x000000	; Couleur: Noir
    call XSetForeground
    ; Draw Point
    mov rdi,qword[display_name]
    mov rsi,qword[window]
    mov rdx,qword[gc]
    mov dword[x], r15d
    mov dword[y], r14d
    mov ecx,dword[x]	; coordonnée source en x
    mov r8d,dword[y]	; coordonnée source en y
    call XDrawPoint
    ; Fin Point
    finForEach:
    inc r14d
    cmp r14d, r9d
    jb forEachLine
inc r15d
cmp r15d, r8d
jb forEachColumn

;#########################################
;#		EXEMPLE UTILISATION XDRAWPOINT   #
;#########################################

;;;couleur du point exemple 1

;mov rdi,qword[display_name]
;mov rsi,qword[gc]
;mov edx,0xFF0000	; Couleur du crayon ; rouge
;call XSetForeground


;;;coordonnées du point exemple 1

;mov dword[x],50
;mov dword[y],50

;;;dessin du point test
;mov rdi,qword[display_name]
;mov rsi,qword[window]
;mov rdx,qword[gc]
;mov ecx,dword[x]	; coordonnée source en x
;mov r8d,dword[y]	; coordonnée source en y
;call XDrawPoint

;##################################################
;#		FIN EXEMPLE UTILISATION XDRAWPOINT        #
;##################################################


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
	