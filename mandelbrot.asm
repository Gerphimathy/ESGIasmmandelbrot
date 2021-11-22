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

section .data

event:		times	24 dq 0

; Nombre Complexe Z
zre: dd 0
zim: dd 0

; Nombre Complexe C
cre: dd 0
cim: dd 0

section .text
	
;##################################################
;########### PROGRAMME PRINCIPAL ##################
;##################################################

main:
; TODO: Name display
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

; TODO: Remove this and scan for the values on program start instead
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



mov r14d, 0 ; y = 0
mov r15d, 0 ; x = 0

; TODO: Remove this and scan for the value on program start instead
mov byte[maxIter], 50

forEachLine: ;for (x = 0; x < width; x++)
    forEachColumn: ;for (y = 0; y < height; y++)

    mov dword[cre], r15d
    mov dword[cim], r14d
    ; c = x (r15) + y(r14)i

    mov dword[zre], 0
    mov dword[zim], 0
    ; z = 0 + 0i

    mov r13b, 0
    ; iteration = 0

        boucleDessin: ;do
        mov rcx, 0
        ;push dword[zre] ; temp = zre
        ; Donne Erreur d'assemblage, utilisation de r10d
        mov r10d, dword[zre]

        ; zre = zre*zre - zim*zim + cre

        mov rbx, sqr ; rbx --> sqr[0]
        mov eax, dword[zre]
        mul dword[zre]
        mov [rbx], eax
        mov [rbx+DWORD], edx
        ; sqr[0] = zre²

        mov rbx, sqr+QWORD ; rbx --> sqr[1]
        mov eax, dword[zim]
        mul dword[zim]
        mov [rbx], eax
        mov [rbx+DWORD], edx
        ; sqr[1] = zim²

        ; TODO: Enforcer une taille limite pour éviter un dépassement de capacité
        mov rax, qword[sqr] ; zre²
        sub rax, qword[sqr+QWORD] ; - zim²
        add rax, r15 ; + cre
        mov dword[zre], eax
        mov rax, 0
        ; zre = zre² - zim² + cre


        ; zim = 2*zim*temp + cim


        ;pop ebx ; ebx = temp
        ; Donne Erreur d'assemblage, utilisation de r10d

        mov ebx, r10d
        shl ebx, 1 ; ebx *= 2

        mov eax, dword[zim]
        mul ebx
        mov ecx, eax ; ecx =  ebx*zim
        ; ecx = 2*temp*zim
        ; TODO: Enforcer une taille limite pour éviter un dépassement de capacité

        add ecx, dword[cim]
        mov dword[zim], ecx
        mov ecx, 0
        ; zim = 2*zim*temp + cim


        inc r13 ; i++

        ; rax = zre*zre + zim*zim

        mov rbx, sqr ; rbx --> sqr[0]
        mov eax, dword[zre]
        mul dword[zre]
        mov [rbx], eax
        mov [rbx+DWORD], edx
        ; sqr[0] = zre²

        mov rbx, sqr+QWORD ; rbx --> sqr[1]
        mov eax, dword[zim]
        mul dword[zim]
        mov [rbx], eax
        mov [rbx+DWORD], edx
        ; sqr[1] = zim²

        mov rcx, qword[sqr] ; rcx = zre²
        add rcx, qword[sqr+QWORD] ; rcx = zre² + zim²

        ; rcx = zre*zre + zim*zim

        ; while zre*zre + zim*zim < 4
        cmp rcx, 4
        jb boucleDessin
        ; and i < maxIter
        cmp r13b, byte[maxIter]
        jb boucleDessin

    cmp r13, maxIter ;if i = maxIter
    jne finForEach
    ; Draw Point
        ; Point Color
        mov rdi,qword[display_name]
        mov rsi,qword[gc]
        mov edx,0x000000	; Black
        call XSetForeground

        ;;;dessin du point
        mov rdi,qword[display_name]
        mov rsi,qword[window]
        mov rdx,qword[gc]
        mov ecx,r15d	; coordonnée source en x
        mov r8d,r14d	; coordonnée source en y
        call XDrawPoint

    finForEach:
    inc r14d
    cmp r14d, dword[height]
    jb forEachColumn
inc r15d
cmp r15d, dword[width]
jb forEachLine

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
	