#!/bin/bash -e
#
#####################################################################
### SCIPT TO DOWNLOAD CLONE cgenie.cookie DIRECTORY 
### N TIMES TO SCRATCH ON REDHAT HPC
#####################################################################

# input variable $1 github user - assuming that genie-main sits in https://github.com/[user]/cgenie.cookie/trunk/genie-main
# input variable $2 number of times to clone
# should be run like: ./cgenie.cookie.scratch.clones.parallel.sh richardstockey 20
# will need to change permissions using chmod +x ~/cgenie.cookie/genie-main/cgenie.cookie.scratch.clones.parallel.sh
# RGS updatesd 20241021 – add in scratch branch as what we are cloning... could make this an option in future if we wanted. 
module load gcc/6.4.0
module load gnumake
module load git

[ -d '/scratch/rgs1e22/cgenie.cookie' ] && rm -rf /scratch/rgs1e22/cgenie.cookie
git clone https://github.com/$1/cgenie.cookie/ /scratch/$USER/cgenie.cookie

# for all batch files we start with the same code here... 
printf "#!/bin/sh

#SBATCH --nodes=1                # Number of nodes requested
#SBATCH --ntasks-per-node=40     # Tasks per node
#SBATCH --time=1:00:00
#SBATCH --mail-user=r.g.stockey@soton.ac.uk
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --output=/home/rgs1e22/cgenie.jobs/cgenie.cookie.scratch.clones.parallel.out

module load gcc/6.4.0
module load gnumake
module load git

LD_LIBRARY_PATH=$HOME/lib
export LD_LIBRARY_PATH

" > ~/cgenie.jobs/cgenie.cookie.scratch.clones.parallel.sbatch

i=1
for clone in $(seq $2)
do
printf "(
## Clean up
[ -d '/scratch/$USER/cgenie.cookie-$clone' ] && rm -rf /scratch/$USER/cgenie.cookie-$clone
[ -d '/scratch/$USER/cgenie.muffin-$clone' ] && rm -rf /scratch/$USER/cgenie.muffin-$clone
# git clone
cp -R /scratch/$USER/cgenie.cookie /scratch/$USER/cgenie.cookie-$clone
# change names in cgenie.cookie-x
cd /scratch/$USER/cgenie.cookie-$clone
grep -l -r 'cgenie.cookie' --exclude-dir='.git' | xargs sed -i 's/cgenie.cookie/cgenie.cookie-$clone/g'
cd /home/$USER/genie.install.stuff
./netcdf.libraries.install.cookie.sh $clone
# return home
cd /home/$USER/
# say we're done with that clone
echo 'cgenie.cookie-$clone created'
) &> ~/cgenie.jobs/cgenie.cookie.scratch.clones.parallel-${clone}.out &
" >> ~/cgenie.jobs/cgenie.cookie.scratch.clones.parallel.sbatch
i=$((i+1))
done

printf "
wait
" >> ~/cgenie.jobs/cgenie.cookie.scratch.clones.parallel.sbatch
cd ~/cgenie.jobs
sbatch cgenie.cookie.scratch.clones.parallel.sbatch