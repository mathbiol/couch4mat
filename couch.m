function [c,d]=couch(c,opt,more)

%COUCH couchdb interoperation in FREEMAT
%for MATLAB version see http://couch4mat.googlecode.com


if exist('c')~=1 %if it is not provided
    c.url='http://localhost:5984';
end

if isempty(c)
    c.url='http://localhost:5984';
elseif ischar(c)
    cc=c;clear c;
    c.url=cc; % so first input argument can be deployment URL
end

if exist('opt')==1
    c.opt=opt;
elseif ~isfield(c,'opt') %if it is not provided
    c.opt='welcome';
end

if exist('more')==1
    c.curl.more=more;
end


switch c.opt
    case 'welcome'
        c=couch_curl(c,'GET');
        c.info=c.curl.json;
    case 'session'
        c=couch_curl(c,'GET','/_session');
        c.session=c.curl.json;
        d=c.session;
        if nargout==1;c=d;end %session info is treated as a document call
    case 'all_dbs'
        c=couch_curl(c,'GET','/_all_dbs');
        c.all_dbs=c.curl.json;
    case 'db'
        if isfield(c.curl,'more');c.db.name=more;end
        c=couch_curl(c,'GET',['/',c.db.name]);
        c.db.info=c.curl.json;
    case 'create db'
        if exist('more')==1;c.db.name=more;end
        c=couch_curl(c,'PUT',['/',c.db.name]);
        c.db.create=c.curl.json;
    case 'delete db'
        %if isfield(c.curl,'more');c.db.name=more;end
        if exist('more')==1;c.db.name=more;end
        c=couch_curl(c,'DELETE',['/',c.db.name]);
        c.db.delete=c.curl.json;
    case 'all_docs'
        if exist('more')==1;c.db.name=more;end
        c=couch_curl(c,'GET',['/',c.db.name,'/_all_docs'],1);
        c.db.all_docs=c.curl.json;
    case 'insert doc' % insert doc, sent it through more
        c=couch_curl(c,'POST',['/',c.db.name,' -H "Content-Type: application/json" -d @curl_in.json'],more);
        d=c.curl.json;
        c.doc=d;
        if nargout==1;c=d;end % being used as a DOC function
    case 'delete doc' % send revision id through more
        if ischar(more) %only the id is being provided
            more=couch_error(couch(c,'doc',more)); %get .rev too
        end            
        c=couch_curl(c,'DELETE',['/',c.db.name,'/',more.id,'?rev=',more.rev]);
        d=c.curl.json;
        c.doc=d;
        if nargout==1;c=d;end % being used as a DOC function
    case 'doc' % get one doc
        c=couch_curl(c,'GET',['/',c.db.name,'/',more],1); %more is doc_id, maybe later work on more.id+more.rev as a structured alternative
        d=c.curl.json;
        c.doc=d;
        if nargout==1;c=d;end % being used as a DOC function
    case 'attach' %attach file to document, passed in through more
        %look for document .id and .rev in c.doc
        if ~isfield(c,'doc');error('document id and rev needs to be provided through c.doc');end
        if ischar(c.doc);% if c.doc = doc.id
            c.doc=couch(c,'doc',c.doc.id);
        end 
        if ~isfield(c.doc,'rev'); % get revision and everything else (there must be a better way to just get rev)
            if isfield(c.doc,'newAttachmentName')
                newAttachmentName=c.doc.newAttachmentName;
            else
                newAttachmentName=more;
            end
            c.doc=couch(c,'doc',c.doc.id);
            c.doc.newAttachmentName=newAttachmentName;
        end
        if ~isfield(c.doc,'newAttachmentName')
            c.doc.newAttachmentName=more; %default attachemnt name is the file name
        end 
        H=''; %Header with file type if available
        if ~isempty(regexp('lala.jpeg','[^\.]\.jpe{0,1}g')) % JPEG IMAGES
            H=' -H "Content-Type: image/jpeg';
        end
        c=couch_curl(c,'PUT',['/',c.db.name,'/',c.doc.id,'/',c.doc.newAttachmentName,'?rev=',c.doc.rev,' --data-binary @',more,H]);
    case 'insert admin' %insert admin user
        if ischar(more);more=json2mat(more);end
        fid=fopen('curl_in.json','w');fprintf(fid,'%s',['"',more.password,'"']);fclose(fid);
        c=couch_curl(c,'PUT',['/_config/admins/',more.username,' -d @curl_in.json']);

    case 'delete admin' %insert admin user
        if ischar(more);more=json2mat(more);end
        c=couch_curl(c,'DELETE',['/_config/admins/',more]);

    otherwise
        error(['Option "',c.opt,'" not recognized'])
end
