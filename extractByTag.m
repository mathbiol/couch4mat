function T=extractByTag(S,t1,t2)
    %extractByTag - remove embedded tatgged patterns
    %Syntax: T=extractByTag(S,t1,t2)
    %where T is a cell array fr each extract
    %S is the target string
    %t1 and t2 are the open and close tags

I1=strfind(S,t1);
I2=strfind(S,t2);

% now screen from each end simultaneously
j=1;
for i=1:length(I1)
    if I2(1)==I1(1)
        

    