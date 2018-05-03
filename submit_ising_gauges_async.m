function [result,gauges] = ...
    submit_ising_gauges_async(h_physical,J_physical,param)
%SUBMIT_ISING_GAUGES_ASYNC submits an physical Ising instance to DWave and returns the
%result and gauges used in various programming cycles. This function splits the large number
%of readouts in manageable number of readouts.
%USAGE:
%   [result,gauges] = submit_ising(h_physical,J_physical,param)
%
%INPUT:
%   h_physical : The physical local fields.
%   J_physical : The physical couplings.
%   param      : parameters to be send to D-Wave
%OUTPUT        :
%   result     : The raw result from D-Wave. A structure array.
%   gauges     : The gauges used in problem submission. The raw results must be transformed
%                to get answers in original gauge.

%Change able parameters.
max_read_per_submission = 1000;
timeOut = 150; % Time out used for submission.

%These parameters never change.
param.auto_scale  = false;
param.answer_mode = 'raw';

%Figure out maximum allowed reads. It is 1k or less, depending on annealing time.
max_reads = floor(0.95*1e6/param.annealing_time);
if max_reads > max_read_per_submission
    max_reads = max_read_per_submission;
end

%And set the anneals to that max value, and set the required programming cycles.
if param.num_reads > max_reads
    progCycles = ceil(param.num_reads/max_reads);
    param.num_reads = max_reads;
else
    progCycles = 1;
end

num_physical_qubits = length(h_physical);
resultLocal   = cell(1,progCycles);
gauges        = zeros(num_physical_qubits,progCycles);
problemTokens = cell(1,progCycles);

%Submit all problems asynchronously
for ii=1:progCycles
    [problemTokens{ii},gauges(:,ii)] = ...
        dwGraph.submit_async_token(h_physical,J_physical,param);
end

%Wait for the time slot to open.
logFile    = fopen('log.txt','at');
[slotOpen,timeToWait] = dwGraph.isTimeSlot();
if ~slotOpen
    fprintf(logFile,'%s : Waiting for time slot to open. \n', datestr(now));
    pause(timeToWait);
    fprintf(logFile,'%s : Slot opened. Resume operations. \n',datestr(now));
end

%Wait for problems to finish completion.
jobsDone = sapiAwaitCompletion(problemTokens,progCycles,timeOut);
while ~jobsDone %While there is a job that is not done.
    %If jobs are not done because they failed, resubmit them. Otherwise, wait more.
    for ii=1:progCycles
        if ~sapiAsyncDone(problemTokens{ii})
            status = sapiAsyncStatus(problemTokens{ii});
            if strcmp(status.state,'FAILED')
                sapiAsyncRetry(problemTokens{ii});
            end
        end
    end
    jobsDone = sapiAwaitCompletion(problemTokens,progCycles,timeOut);
end

%Retrieve result and sparse them out to save space.
for ii=1:progCycles
    temp_result           = sapiAsyncResult(problemTokens{ii});
    soln                  = temp_result.solutions;
    soln(soln==3)         = 0;
    temp_result.solutions = sparse(soln);
    resultLocal{ii}       = temp_result;
 fprintf(logFile,'%s : %s : Result gathered.\n',...
            datestr(now),problemTokens{ii}.handle.problem_id);
end

%Compress the results.
result = cell2mat(resultLocal);

fclose(logFile);
end
