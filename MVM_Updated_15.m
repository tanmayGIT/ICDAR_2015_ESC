function [pathCost,pathTarget,indxcol,indxrow,distSum,jumpcost] = MVM_Updated_15(refSample,testSample,weight,straight)
pathTarget = 1;
[noOfSamplesInRefSample,N] = size(refSample);
[noOfSamplesInTestSample,M] = size(testSample);

gMan = 0.05;
cenEle = round(noOfSamplesInTestSample/2);
if(noOfSamplesInRefSample == 0)
    disp('This is unwanted/unknown error');
end

if(N == M)
    Dist = zeros(noOfSamplesInRefSample,noOfSamplesInTestSample);
    pathCost = inf(noOfSamplesInRefSample,noOfSamplesInTestSample);
    pathTargetRw = zeros(noOfSamplesInRefSample,noOfSamplesInTestSample);
    pathTargetCol = zeros(noOfSamplesInRefSample,noOfSamplesInTestSample);
    
    for i=1:noOfSamplesInRefSample
        for j=1:noOfSamplesInTestSample
            total = zeros(N,1);
            for goFeature = 1:N
                total(goFeature,1) = (double((refSample(i,goFeature)-testSample(j,goFeature))^2));
            end
            
            Dist(i,j) = sqrt(sum(total));
        end
    end
    grac = ones(noOfSamplesInRefSample,noOfSamplesInTestSample);
    Dist = Dist + grac;
    elasticity = noOfSamplesInTestSample-noOfSamplesInRefSample;
    fullElasticity = (noOfSamplesInTestSample);
    
    if (~exist('jumpcost','var'))
        statmatx = min(Dist,[],2);
        [~,~,statmatx] = find(statmatx);
        if(isempty(statmatx))
            jumpcost = 0;
        else
            jumpcost = ( (mean(statmatx)+ 1*std(statmatx)) );
        end
    end
    
    if(noOfSamplesInTestSample >= noOfSamplesInRefSample)
        pathCost(1,1) = Dist(1,1);
        for ji = 2:1:(noOfSamplesInTestSample)
            pathCost(1,ji) = Dist(1,ji) ;%+ pathCost(1,ji-1);
        end
        for i = 2:1:noOfSamplesInRefSample
            if(i == 2)
                stopMotherRight = min((i-1+(fullElasticity)),noOfSamplesInTestSample);
                stopMotherLeft = max(((i-1)-(fullElasticity)),1);
            else
                stopMotherRight = min((i-1+(elasticity)),noOfSamplesInTestSample);
                stopMotherLeft = max(((i-1)-(elasticity)),1);
            end
            for k = stopMotherLeft:1:stopMotherRight
                stopj = min(((k+1+elasticity)-(abs(k-(i-1)))),noOfSamplesInTestSample);
                stopLeft  = max(k,1);
                for j = (stopLeft):1:stopj
                    if(j == stopLeft)
                        if ((pathCost(i,j)) >  (pathCost(i-1,k) + Dist(i,j)))
                            pathCost(i,j) = ((pathCost(i-1,k) + (Dist(i,j))));
                            
                            pathTargetRw(i,j) = i-1;
                            pathTargetCol(i,j) = k;
                        end
                    else
                        if ((abs(j-(k+1))) == 0)
                            costJump = 0;
                        else
                            myDiff = 0;
                            for sumNois = i:1:j-1 % k+1-1 is to get number of jumped elements particularly
                                myDiff = myDiff + Dist(i,sumNois);
                            end
                            weight = 1.0 ./ (1.0 + (exp(-gMan*(myDiff - cenEle))) );
                            costJump = (jumpcost*weight)*(abs(j-(k+1)));
                        end
                        if ((pathCost(i,j)) >  (( (pathCost(i-1,k) + ((Dist(i,j)))) + costJump ) ))
                            pathCost(i,j) = (( (pathCost(i-1,k) + ((Dist(i,j)))) + costJump )) ;
                            
                            pathTargetRw(i,j) = i-1;
                            pathTargetCol(i,j) = k;
                        end
                    end
                    takeMin = max(1,j-1);
                    if( (pathCost(i,j) > (pathCost(i,takeMin) + Dist(i,j)))  )
                        pathCost(i,j) =   pathCost(i,takeMin) + Dist(i,j) ;
                        pathTargetRw(i,j) = i;
                        pathTargetCol(i,j) = j-1;
                    end
                end
            end
        end
        
        lastElasticity = max((noOfSamplesInRefSample),1);
        [minVal,~] = min(pathCost(noOfSamplesInRefSample,lastElasticity:noOfSamplesInTestSample));
        tempArr = pathCost(noOfSamplesInRefSample,lastElasticity:noOfSamplesInTestSample);
        ind = find(tempArr == minVal);
        indices = max(ind);
        
        mincol = (lastElasticity-1)+indices;
        minrow = noOfSamplesInRefSample;
        
        Wrapped =[];
        while (minrow>=1 && mincol>=1)
            Wrapped = cat(1,[minrow,mincol],Wrapped);
            if(minrow == 1)&&(mincol == 1)
                break;
            end
            mincolTemp = pathTargetCol(minrow,mincol);
            minrow = pathTargetRw(minrow,mincol);
            mincol = mincolTemp;
        end
        indxrow = Wrapped(:,1);
        indxcol = Wrapped(:,2);
        
        distSum = pathCost(indxrow(end,1),indxcol(end,1));
        
        distSum = ((distSum))/(size(indxcol,1));
        return
    end
end
