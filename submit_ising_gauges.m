function [result,gauges] = submit_ising_gauges(h_physical,J_physical,param)
%SUBMITINSTANCE submits an physical Ising instance to DWave and returns the result and
%gauges used in various programming cycles.
%USAGE:
%   [result,gauges] = submit_ising(h_physical,J_physical,param)
%
%INPUT:
%   h_physical  : The physical local fields.
%   J_physical  : The physical couplings.
%       Couplings will be scaled down to [-1,1] range if necessary. No scale up would be done.
%   param      : parameters to be send to D-Wave
%OUTPUT:
%   result     : The raw result from D-Wave. A structure array.
%   gauges     : The gauges used in problem submission. The raw results must be transformed
%                to get answers in original gauge.

%These parameters never change.
param.auto_scale  = false;
param.answer_mode = 'raw';
numQubits         = length(h_physical);

%Manually scale the couplings and local fields of physical Hamiltonian.
J_max = max(abs(J_physical(:))); h_max = max(abs(h_physical(:)));
scaleFactor = max([J_max h_max 1]);
h_physical = h_physical/scaleFactor; J_physical = J_physical/scaleFactor;

%Figure out maximum allowed reads. It is 1000 or less, depending on annealing time.
max_reads = floor(0.95*1e6/param.annealing_time);
if max_reads > 1000
    max_reads = 1000;
end

%And set the anneals to that max value, and set the required programming cycles.
if param.num_reads > max_reads
    progCycles = ceil(param.num_reads/max_reads);
    param.num_reads = max_reads;
else
    progCycles = 1;
end
resultLocal = cell(1,progCycles);
gauges      = zeros(numQubits,progCycles);

%Submit the chain to D-Wave, and return the result.

%Open an error file to write errors. This will help in not polluting main
%window.
fileHandle = fopen('errors.txt','at');
logFile    = fopen('log.txt','at');

persistent solver; persistent shouldRenewSolver ;

for iiProgCycle = 1:progCycles
    while(true)
        try
            if( isempty(solver) || shouldRenewSolver)
                %(Re)Initialise D-Wave
                load('solverSettings.mat','urlDwave','myToken','solverName');
                while(true)
                    try
                        connHandle        = sapiRemoteConnection(urlDwave,myToken);
                        solver            = sapiSolver(connHandle,solverName);
                        shouldRenewSolver = false;
                        break;
                    catch errorE
                        disp(errorE)
                        fprintf(['Fatal error in creating a solver. Are you sure you can connect' ...
                                 ' to D-Wave? \n']);

                        fprintf('Retrying ...\n');
                    end
                end
            end

            resultCaptured = false;
            normalWaitTime = 100; %Wait for this many seconds normally to gather result.

            while ~resultCaptured

                [slotOpen,timeToWait] = isTimeSlot();
                if ~slotOpen
                    fprintf(logFile,'%s : Waiting for time slot to open. \n', datestr(now));
                    pause(timeToWait);
                    fprintf(logFile,'%s : Slot opened. Resume operations. \n',datestr(now));
                end

                %Apply gauge and submit the problem.
                localGauge = 2*randi([0 1],numQubits,1)-1;
                gauges(:,iiProgCycle) = localGauge;
                h_gauged = dot(localGauge,h_physical);
                J_gauged = (localGauge*localGauge').*J_physical;

                problemToken = sapiAsyncSolveIsing(solver,h_gauged,J_gauged,param);
                problemToken = sapiAwaitSubmission({problemToken}, normalWaitTime);
                if isempty(problemToken{1})
                    errObj = MException('sapi:ProblemSubmissionFailed',...
                                        'Can not submit problem in %g seconds',...
                                        normalWaitTime);
                    throw(errObj);
                end

                problemID    = problemToken{1}.handle.problem_id;
                [slotOpen,timeToWait] = isTimeSlot();
                fprintf(logFile,'%s : %s : Submitted a job. Waiting for %g seconds\n',...
                        datestr(now),problemID,timeToWait+normalWaitTime);

                if slotOpen %Wait for normal wait time.
                    isDone = sapiAwaitCompletion(problemToken,1,normalWaitTime);
                else %Wait for slot to open, and then the normal wait time.
                    isDone = sapiAwaitCompletion(problemToken,1,normalWaitTime+timeToWait);
                end

                if isDone
                    resultCaptured = true;
                else
                    fprintf(logFile,'%s : %s : Job expired without results\n',...
                            datestr(now),problemID);
                end
            end

            resultLocal{iiProgCycle} = sapiAsyncResult(problemToken{1});
            fprintf(logFile,'%s : %s : Result gathered for problem cycle %d\n',...
                                datestr(now),problemID,iiProgCycle);
            break;
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
    end %End of 1 programming cycle.
end %End programming cycles.

fclose(fileHandle);
fclose(logFile);

%Join all the different programming cycles.
if progCycles == 1
    result = resultLocal{1};
else
    result = cell2mat(resultLocal);
end

end
