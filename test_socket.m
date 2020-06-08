tc = tcpip('0.0.0.0', 8082, 'NetworkRole', 'server');
    set(tc,'InputBufferSize', 4096);
    set(tc,'OutputBufferSize', 4096);
    set(tc,'Timeout', 30);
    fprintf(1, 'waiting for network connection\n');
fopen(tc); 
    fprintf(1, 'network open\n');