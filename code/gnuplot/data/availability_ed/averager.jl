using DelimitedFiles

function averager(files, cis, scales, algs, outfile)
    Z = zeros(scales, algs + 1)
    for i = 1:length(files)
        f = readdlm(files[i])
        if cis[i]
            for alg = 1:algs
                println((alg - 1) * 3 + 2)
                Z[:, alg+1] .+= f[:, (alg-1)*3+2]
            end
        else
        end
        Z[:, 1] = f[:, 1]
        println(Z)
    end
    for i = 2:size(Z, 2)
        Z[:, i] = Z[:, i] ./ length(files)
    end
    writedlm(outfile, Z)
end

averager(
    ["./B4_ed_availability_ci", "./IBM_ed_availability_ci"],
    [true, true],
    26,
    5,
    "./averaged.txt",
)
