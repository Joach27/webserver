# ----------By Joach27 -----------
# Web server in assembly language
# --------------------------------

.intel_syntax noprefix
.global _start

.section .text
_start:

    #------ SOCKET-------
    # socket (AF_INET, SOCK_STREAM, 0)
    mov rdi, 2      # AF_INET
    mov rsi, 1      # SOCK_STREAM
    mov rdx, 0      # protocol = 0 (IPPROTO_IP)
    mov rax, 41     # Syscall number for socket
    syscall

    # moving the sockfd to rdi
    mov rdi, rax
    mov r15, rax

    #------ BIND -------
    # bind(sockfd, addr, addrlen) syscall
    lea rsi, [rip+sockaddr]
    mov rdx, 16
    mov rax, 0x31
    syscall

    #------ LISTEN ---------
    # performing the rest of the syscall (LISTEN)
    mov rsi, 0    # Max number of queued conncetion
    mov rax, 0x32     # syscall number for LISTEN (50 en deciaml)
    syscall

    #------ ACCEPT syscall -------
    # accept(sockfd, addr, addrlen)
    mov rsi, 0
    mov rdx, 0
    mov rax, 43
    syscall

    #--- FORK ---
    mov rax, 0x39
    syscall

    # Check if child process is
    cmp rax, 0
    je Child_process

Parent_process:
    # close the accepted connection
    mov rdi, 4                      # file descriptor (for client connection)
    mov rax, 0x3                    # close syscall number
    syscall

    # ACCEPT syscall
    mov rdi, r15        # (3 typically)
    mov rsi, 0
    mov rdx, 0
    mov rax, 43
    syscall

Child_process:
    # Close the socket listener
    mov rdi, 3                      # file descriptor (for socket listener)
    mov rax, 0x3                    # close syscall number
    syscall


    # read (fd, read_request, request_length)    
    mov rdi, 4
    mov rsi, rsp
    mov rdx, 256        #146(possible?)
    mov rax, 0x00
    syscall

    # Saving the buffer sent by the user
    mov r10, rsp

    # Parsing GET
Parsing_GET:
    mov al, byte ptr [r10]
    cmp al, ' '
    je Done_1
    add r10, 1
    jmp Parsing_GET

Done_1:
    add r10, 1          # Point to the next byte
    mov r11, r10        # Making r11 start at the path beginning

    # Parse the PATH
Parsing_PATH:
    mov al, byte ptr [r11]
    cmp al, ' '
    je Done_2
    add r11, 1
    jmp Parsing_PATH

Done_2:
    mov byte ptr [r11], 0       # Indicate the end of file

    # OPEN syscall
    mov rdi, r10        # path
    mov rsi, 0          # O_READ_ONLY
    mov rdx, 0
    mov rax, 0x02       # OPEN syscall number is 2
    syscall

    # READ Syscall
    mov rdi, 3
    mov rsi, rsp        # Reading to the stack
    mov rdx, 256
    mov rax, 0x00
    syscall

    mov r12, rax       # Saving the result of READ call

    # close(fd) syscall for file desc 5
    mov rdi, 3                      # file descriptor (for the opened file)
    mov rax, 0x3                    # close syscall number
    syscall

    # write(fd, buffer, buffer_size)
    mov rdi, 4                      # Putting the accept file descriptor in rdi for the write call
    lea rsi, [rip + response]       # buffer
    mov rdx, 19                     # buffer length
    mov rax, 0x01                   # write syscall number
    syscall

    # WRITE syscall 
    # Sending the file content back to the client
    mov rdi, 4
    mov rsi, rsp
    mov rdx, r12
    mov rax, 0x01
    syscall


    # close(fd) syscall
    mov rdi, 4                      # file descriptor (for client connection)
    mov rax, 0x3                    # close syscall number
    syscall

    # ACCEPT syscall
    mov rdi, r15
    mov rsi, 0
    mov rdx, 0
    mov rax, 43
    syscall


    
    #------- EXITING --------
    # exiting
    mov rdi, 0
    mov rax, 60
    syscall


.section .data
sockaddr:
    .2byte 2        # AF_INET
    .2byte 0x5000   # Port number
    .4byte 0        # Port, ex: 0.0.0.0
    .8byte  0       # Padding

response:
    .string "HTTP/1.0 200 OK\r\n\r\n"
