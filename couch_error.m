function x=couch_error(x) 

%COUCH_ERROR reports couchdb errors
if isstruct(x)
    if isfield(x,'error')
        if isfield(x,'reason')
            error(['CouchDB Error: ',x.error,'; Reason: ',x.reason])
        end
    end
end