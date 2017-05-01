function [ StimTimes ] = StimTimeInterpolate( nStims, StimTimes )
%StimTimeInterpolate Try to interpolate missing stim times

    if std(diff(StimTimes)) > 10 % nonlinear
        return
    end
    
    if length(StimTimes) < nStims/2 % lost cause
        return
    end

    while ( abs(min(diff(StimTimes)) - median(diff(StimTimes))) >= ...
            std(diff(StimTimes)) )
        
        % Remove extra stim times
        mv = min(diff(StimTimes));
        idx = find(diff(StimTimes) == mv,1);
        StimTimes = [StimTimes(1:idx); StimTimes(idx+2:end)];
    end
    
    while ( length(StimTimes) < nStims && ...
            abs(max(diff(StimTimes)) - median(diff(StimTimes))) >= ...
            std(diff(StimTimes)) )
        
        % Add missing stim times
        mv = max(diff(StimTimes));
        idx = find(diff(StimTimes) == mv);
        StimTimes = fillmissing([StimTimes(1:idx); NaN; StimTimes(idx+1:end)],'linear');
    end
    
    while length(StimTimes) < nStims
        
        % Add missing stim times to beginning or end?
        if (min(diff(StimTimes)) - StimTimes(1) < 0)
            StimTimes = fillmissing([NaN; StimTimes],'linear');
        else
            StimTimes = fillmissing([StimTimes; NaN],'linear');
        end
    end
end

