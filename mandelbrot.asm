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

section .data

event:		times	24 dq 0

x:	dd	0
y:	dd	0

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
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
mov r8,400	; largeur
mov r9,400	; hauteur
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
	