function y=cell2freemat(x)
%CELL2FREEMAT mimiking matlab's homonimous function

go_numeric=0;
go_struct=0;
if iscell(x(1))
    go_numeric=1;
    go_struct=1;
    if isstruct(x{1});%if this is a cell array of structures un-cell it
        go_numeric=0;
        for i=1:length(x)
            if isstruct(x{i})==0
                gostruct==0;
            end
        end
    else %try numeric
        n=length(x{1});
        for i=1:length(x)%check if isnum or is cell and if teh size is always the same
            if (isnumeric(x{i})*(length(x{i})==n))==0
                go_numeric=0;
            end % it only takes one exception to break it
        end
    end
end

if go_numeric==1
    xx=[x{:}];
    y=xx';
elseif go_struct==1
    y=[x{:}];
else
    y=x;
end
