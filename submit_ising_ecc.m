function result = submit_ising_ecc(h_logical,J_logical,param,translateFnHandle)
%SUBMITINSTANCE submits an physical Ising instance to DWave and returns the result.
%USAGE:
%   result = submit_ising(h_physical,J_physical,param)
%
%INPUT:
%   h_logical  : The physical local fields.
%   J_logical  : The physical couplings.
%       Coulings will be scaled down to [-1,1] range if necessary. No scale up would be done.
%   param      : parameters to be send to DW2.
%   tranlateFnHandle : A handle to function that can convert logical to physical Ham.
%OUTPUT:
%   result     : The raw result from D-Wave

%These parameters never change.
param.auto_scale  = false;
param.answer_mode = 'raw';

%Manually scale the couplings and local fields of logical hamiltonian.
J_max = max(abs(J_logical(:))); h_max = max(abs(h_logical(:)));
scaleFactor = max([J_max h_max 1]);
h_logical = h_logical/scaleFactor; J_logical = J_logical/scaleFactor;


%Convert to physical Hamiltonian with external energy scale and penalty couplings.
[h_physical,J_physical] = translateFnHandle(h_logical,J_logical);

%Open an error file to write errors. This will help in not polluting main
%window.
fileHandle = fopen('errors_ecc.txt','at');

persistent solver; persistent shouldRenewSolver ;

while(true)
    try
        if( isempty(solver) || shouldRenewSolver)
            %(Re)Initialise Vesuvious
            load('solverSettings.mat','urlDwave','myToken','solverName');
            while(true)
                try
                    connHandle = sapiRemoteConnection(urlDwave,myToken);
                    solver = sapiSolver(connHandle,solverName);
                    shouldRenewSolver = false;
                    break;
                catch errorE
                    disp(errorE)
                    fprintf(['Fatal error in creating a solver. Are you sure you can connect' ...
                             ' to DW2? \n']);

                    fprintf('Retrying ...\n');
                end
            end
        end

        %Use asynchronous submission method.
        resultCaptured = false;
        normalWaitTime = 100; %Wait for this many seconds normally to gather result.

        while ~resultCaptured
            problemToken = sapiAsyncSolveIsing(solver,h_physical,J_physical,param);
            [slotOpen,timeToWait] = isTimeSlot();
            if slotOpen %Wait for normal wait time.
                isDone = sapiAwaitCompletion({problemToken},1,normalWaitTime);
            else %Wait for slot to open, and then the normal wait time.
                isDone = sapiAwaitCompletion({problemToken},1,normalWaitTime+timeToWait);
            end

            if isDone
                resultCaptured = true;
            end
        end

        result = sapiAsyncResult(problemToken);
        break;

    catch errorObject
        fprintf('!*');
        fprintf(fileHandle, '%s : Error identifier \"%s\" \n',datestr(now), ...
                errorObject.identifier);
        fprintf(fileHandle, '%s : Error message \" %s \" \n' ,datestr(now),errorObject.message);
        pause(5);
        if strcmp(errorObject.identifier,'sapi:NetworkError')
            shouldRenewSolver = true;
        end
    end
end

fclose(fileHandle);

end
