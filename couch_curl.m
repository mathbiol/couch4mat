function c=couch_curl(c,method,more_url,file)

%COUCH_CURL makes CURL calls on behalf of COUCH
%c is COUCH's object model
%method is GET, POST, PUT, DELETE
%file can be 1 (true) to indicate that the oucome needs to be passed through a file
%file can be a structure which will be converted to json string first and then
%file can be a json string which will be submitted

if nargin<1
    c='http://localhost:5984';
end
if ischar(c)
    u=c;clear c;c.url=u; %clear is for teh benefit of freemat, matlab doesn't need it
end
if nargin<2
    method='GET';
end

if exist('more_url')~=1
    more_url='';
end
u=[c.url,more_url];
c.curl.msg='';

%check for authentication
if isfield(c,'auth')
    uu=regexp(u,'(https*://)(.+)','tokens');uu=uu{1};
    u=[uu{1},c.auth.username,':',c.auth.password,'@',uu{2}];
end

% SYSTEM check
if ~isfield(c.curl,'system') %find out how many output arguments to command system
    if isnumeric(system(['curl ',c.url]))
        c.curl.system=2; %Matlab 
    else
        c.curl.system=1; %Freemat 
    end
end

% FILE check
if exist('file')==1
    %check if this is json being sent in as the third argument
    if ischar(file)
        if file(1)=='{';
            if c.curl.system==2 % Matlab
                file=json2mat(file);
            else %freemat
                file=json2freemat(file);
            end
        end
    end
    if ischar(file) %this is a filename being submited for insertion
        if exist(file)==2 % check that the file can be read
            % In progress
            % ...
        else
            error(['File "',file,'" cannot be found/read']);
        end
    elseif isstruct(file) % this is a document being submitted as a structure --> push it to curl_in.json
        d=mat2json(file);
        fid=fopen('curl_in.json','w');fprintf(fid,'%s',d);fclose(fid);
    elseif iscell(file)
        error('Document must be a structure such that couch can assign values to document attributes')
    elseif file==1 %retrienving large json structures requires mediation by curl_out.json
        u=[u,' -o curl_out.json'];
    else
        error(['argument more=',file,' not recognized'])
    end
    %if c.curl.system==2 % Matlab
end

if c.curl.system==2 % Matlab
    [c.curl.ans,c.curl.msg]=system(['curl -kX ',method,' ',u]);
    c.curl.call=['curl -kX ',method,' ',u]; %reccord the actual url call
    f=regexp(c.curl.msg,'[\[\{]');
    if isempty(f)
        c.curl.msg='';
    else
        c.curl.msg(1:f(1)-1)=[];
    end
    if exist('file')==1
        if isnumeric(file)
            if file==1
                fid=fopen('curl_out.json','r');
                c.curl.msg='';while ~feof(fid);c.curl.msg=[c.curl.msg,fgetl(fid)];end
                fclose(fid);
            end
        end
    end
    c.curl.json=json2mat(c.curl.msg); %results stored back here
else % Freemat
    c.curl.msg=system(['curl -kX ',method,' ',u]);
    c.curl.call=['curl -kX ',method,' ',u]; %reccord the actual url call
    if isempty(c.curl.msg)
        c.curl.msg='';
    else
        c.curl.msg=c.curl.msg{1};
    end
    if exist('file')==1
        if isnumeric(file)
            if file==1
                fid=fopen('curl_out.json','r');
                c.curl.msg='';while ~feof(fid);c.curl.msg=[c.curl.msg,fgetline(fid)];end
                fclose(fid);
            end
        end
    end
    c.curl.json=json2freemat(c.curl.msg); %results stored back here
end

