function [c,doc]=couch(c,opt,more)

%couch main function to interoperate with CouchDB
%Syntax is loosely based on that of /script/couch.js

% Take care of default values

if nargin==0
    c='';
end

if isempty(c) %use local deployment
    c.url='http://127.0.0.1:5984';
elseif ischar(c)
    u=c;clear c;
    c.url=u;
end 

if exist('opt')
    c.opt=opt;
end

if ~isfield(c,'opt')
    c.opt='welcome'; %list all dbs
end


switch c.opt
    case 'auth' %configuring access to a cloundant.com couchdb account, not tested for others yet
        if ischar(more);more=json2mat(more);end
        c.auth=more; %should contain username and password fields
        c=couch(c,'welcome');
    case 'welcome'
        a=couch_urlread(c.url,c);a(a==10)=[];
        c.welcome=json2mat(a);
    case 'all_dbs' %list all dbs
        c.all_dbs=json2mat(couch_urlread([c.url,'/_all_dbs'],c));
        
    case 'create db' %creates db: couch(url,'create db','dbName')
        if exist('more')==1 % remember more is also a built-in function, exist(varName)==1 when it is a variable in the workspace
            c.db.name=more;
        end
        c=couch_curl(c,['curl -X PUT ',c.url,'/',c.db.name]);
        %[c.sys.ans,c.sys.msg]=system(['curl -X PUT ',c.url,'/',c.db.name]);
        %c.sys.json=regexp(c.sys.msg,'(\{[^\{].+\})','tokens');
        %c.sys.json=json2mat(c.sys.json{1}{1});
        %err_sys(c.sys);
        
    case 'insert doc' % insert single document to database
        couch_check_db(c);
        % check also that doc is provided
        if nargin<3
            error('What doc do you want to insert? empty doc ok, just use ''{}'' as third input argument')
        end
        uuid=get_uuid(c);
        c=couch_curl(c,['-kX PUT ',c.url,'/',c.db.name,'/',uuid],more,uuid);
        doc=c.cURL.json;
        if nargout<2;c=doc;end %return doc if only one output argument
    case 'db' % set target db
        c.db.name=more;
        c=couch_curl(c,[' -k ',c.url,'/',c.db.name]);
        c.db.welcome=c.cURL.json;
        
    case 'all_docs' %list all documents in a database
        if exist('more')==1;c.db.name=more;end
        couch_check_db(c);
        c=couch_curl(c,['-kX GET ',c.url,'/',c.db.name,'/_all_docs']);
        c.db.all_docs=c.cURL.json;
        %c.db.all_docs=json2mat(couch_urlread([c.url,'/',c.db.name,'/_all_docs'],c));
        
    case 'get doc' %get a specific doc
        couch_check_db(c);
        doc=json2mat(couch_urlread([c.url,'/',c.db.name,'/',more],c));
        %c=couch_curl(c,['-X GET ',c.url,'/',c.db.name,'/',more]); % cURL doesn't do as well as url read for long entries
        %doc=c.cURL.json;
        if nargout<2;c=doc;end %if there is only one output argument let it be doc
        
    case 'delete db'
        if exist('more')==1;c.db.name=more;end
        couch_check_db(c);
        c=couch_curl(c,['-X DELETE ',c.url,'/',c.db.name]);
        
    case 'delete doc'
        doc=couch(c,'get doc',more); %get document to find out its revision id
        c=couch_curl(c,['-X DELETE ',c.url,'/',c.db.name,'/',doc.id,'?rev=',doc.rev]);
        %if all_docs exists update the list
        if nargout<2
            c=doc; %if there is only one output argument let it be deleted doc
        elseif isfield(c.db,'all_docs') %otherwise try to update c
            %updating c.db.all_docs
            Ind=find(strcmp(doc.id,{c.db.all_docs.rows.id}));
            if ~isempty(Ind);
                c.db.all_docs.rows(Ind)=[];
                c.db.all_docs.total_rows=c.db.all_docs.total_rows-length(Ind); %length(Ind) should be 1 of course
            end
        end
end


function couch_check_db(c) %check that db name is provided
if ~isfield(c,'db')
    error('What database do you want to use? Please provide that information through c.db.name or as an additional argument');
elseif ~isfield(c.db,'name')
    error('What database do you want to use? Please provide that information through c.db.name or as an additional argument');
end

function uuid=get_uuid(c) %get universal unique identifier

if ischar(c) %c is a url
    c.url=c;
end
uuid=regexp(couch_urlread([c.url,'/_uuids'],c),'\["(.+)"\]','tokens');
uuid=uuid{1}{1};

function c=couch_curl(c,x,json,id) %manages use of cURL

%COUCH_CURL uses cURL with a couch specific syntax
%           c is the couchdb c structure
%           x is curl command
%           more contains JSON to be passed as a "-d @file"
%           if more is nos a string it will be first converted by mat2json
%
%Jonas Almeida, April 2010

if nargin>2
   if nargin>3 %use this identifier
        f=['couch_',id,'.json'];
    else %create nadom string
        f=['couch_',strrep(sprintf('%.17f',rand()),'0.',''),'.json'];
    end
    if ~ischar(json)
        if ~isstruct(json) %remember input docs have to be json objects
            error('CouchDB docs have to be JSON objects <-- Matlab structures')
        end
        json=mat2json(json);
    end
    fid=fopen(f,'w');
    fprintf(fid,'%s',json);
    fclose(fid);
    x=[x,' -d @',f];
end
if isfield(c,'auth')%check for authentication
    xx=regexp(x,'(.*https*://)(.+)','tokens');xx=xx{1};
    x=[xx{1},c.auth.username,':',c.auth.password,'@',xx{2}];
end    
c.cURL.call=x;
[c.cURL.ans,c.cURL.msg]=system(['curl ',x]);
c.cURL.json=regexp(c.cURL.msg,'(\{[^\{].+\})','tokens');
c.cURL.json=json2mat(c.cURL.json{1}{1});
err_sys(c.cURL);

% Keep the number of couch_*.json files in check
d=dir('couch_*.json');
if length(d)>10
    delete(d(1:end-5).name) %between 5 and 10
end

function err_sys(x) % x <- c.cURL, reports errors
if isfield(x.json,'error')
    error(x.json.reason);
end

function y=couch_urlread(u,c)

%COUCH_URLREAD version of URLREAD that takes care of autentication
if isfield(c,'auth')
    uu=regexp(u,'(https*://)(.+)','tokens');uu=uu{1};
    u=[uu{1},c.auth.username,':',c.auth.password,'@',uu{2}];
end
try
    y=urlread(u);
catch
    error('insuficient permissions')
end
    
        
