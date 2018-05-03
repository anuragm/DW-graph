function [problemToken,gauge] = submit_async_token(h_physical,J_physical,param)
%SUBMIT_ASYNC_TOKEN asynchronously submits one problem to the machine with specific
% gauge. Returns the token to the submitted problem and the gauge used. Tokens
% are returned only for a successfully submitted problem. Should the problem
% submission fail, it is retried until a successful submission happens.
%  USAGE:
%   [problemToken,gauge] = submit_async_token(h_physical,J_physical,param)

% INPUT:
%   h_physical : The physical local fields.
%   J_physical : The physical couplings.
%   param      : parameters to be send to D-Wave. Refer D-Wave guide.
% OUTPUT:
%  problemToken : A D-Wave structure which contains the problem token. This can be passed on
%                 to other function for checking status, waiting for completion, etc.
%  gauge        : The gauge applied on the input problem.

normalWaitTime = 100; %In seconds.

%Apply the required gauge.
numQubits = length(h_physical);
gauge     = 2*randi([0 1],numQubits,1)-1;
h_gauged  = dot(gauge,h_physical);
J_gauged  = (gauge*gauge').*J_physical;


%Open an error file to write errors.
fileHandle = fopen('errors.txt','at');
logFile    = fopen('log.txt','at');

%Get a solver and a token which decides that the solver should be renewed.
persistent solver; persistent shouldRenewSolver ;

%Set this to true when asynchronous submission succeeds. Else try again.
jobSubmitted = false;
while ~jobSubmitted
    try
        %Make a connection if the flag is set, or if this is the first attempt to connect to
        %the server.
        if( isempty(solver) || shouldRenewSolver)
            %(Re)Initialise D-Wave
            solver = initialize_dwave();
            shouldRenewSolver = false;
        end

        %We have the solver now. Problems can be submitted to the annealer even if we are
        %out of our time slot.

        problemToken = sapiAsyncSolveIsing(solver,h_gauged,J_gauged,param);
        problemToken = sapiAwaitSubmission({problemToken}, normalWaitTime);
        if isempty(problemToken{1})
            errObj = MException('sapi:ProblemSubmissionFailed',...
                                'Can not submit problem in %g seconds',...
                                normalWaitTime);
            throw(errObj);
        end

        %If control reaches here, it means we have successfully submitted the problem.
        problemID    = problemToken{1}.handle.problem_id;
        fprintf(logFile,'%s : %s : Submitted a job.\n',...
                datestr(now),problemID);
        jobSubmitted = true;
        problemToken = problemToken{1}; %Remove the outer cell structure.

    catch errorObject
        fprintf('!*');
        fprintf(fileHandle, '%s : Error identifier \"%s\" \n',datestr(now), ...
                errorObject.identifier);
        fprintf(fileHandle, '%s : Error message \" %s \" \n' ,datestr(now), ...
                errorObject.message);
        pause(5);
        if strcmp(errorObject.identifier,'sapi:NetworkError')
            shouldRenewSolver = true;
        end
    end
end

fclose(fileHandle);
fclose(logFile);

end %End of function

function solver = initialize_dwave()
    load('solverSettings.mat','urlDwave','myToken','solverName');
    while(true)
        try
            connHandle        = sapiRemoteConnection(urlDwave,myToken);
            solver            = sapiSolver(connHandle,solverName);
            break;
        catch errorE
            disp(errorE)
            fprintf(['Fatal error in creating a solver. Are you sure you can connect' ...
                     ' to D-Wave? \n']);

            fprintf('Retrying ...\n');
        end
    end
end
