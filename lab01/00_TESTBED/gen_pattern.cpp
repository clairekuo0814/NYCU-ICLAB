#include <iostream>
#include <fstream>
#include <cstdlib>
#include <ctime>
#include <algorithm>

using namespace std;

void gen_input(int* w, int* vgs, int* vds);
int gen_output(int* w, int* vgs, int* vds, int mode);


int main(){
    ofstream INPUT("gen_input_3.txt");
    //ifstream INPUT("input.txt");
    ofstream OUTPUT("gen_output_3.txt");
    
    const int PAT_NUM = 100000;
    INPUT << PAT_NUM << '\n';
    INPUT << '\n';
    srand(time(NULL));
    /*int PAT_NUM;
    INPUT >> PAT_NUM;*/
    for(int i=0; i < PAT_NUM; i++){
        //INPUT << "//" << i << '\n';
        
        int mode;
        mode = rand()%4;
        int w[6], vgs[6], vds[6];
        //gen_input(w, vgs, vds); 
        INPUT << mode << '\n';
        for(int j=0; j < 6; j++){
            w[j] = rand()%7 + 1;
            vgs[j] = rand()%7 + 1;
            vds[j] = rand()%7 + 1;
            INPUT << w[j] << " " << vgs[j] << " " << vds[j] << '\n';
        }
        INPUT << '\n';
        
        /*int mode;
        INPUT >> mode;
        int w[6], vgs[6], vds[6];
        for(int i=0; i < 6; i++){
            INPUT >> w[i];
            INPUT >> vgs[i];
            INPUT >> vds[i];
        }*/
        int ans = gen_output(w, vgs, vds, mode);
        OUTPUT << ans << '\n';
    }

}

//int main(){
//    ofstream INPUT("gen_input_2.txt");
//    //ifstream INPUT("input.txt");
//    ofstream OUTPUT("gen_output_2.txt");
//    
//    const int PAT_NUM = 49;
//    INPUT << PAT_NUM << '\n';
//    INPUT << '\n';
//    //srand(time(NULL));
//    /*int PAT_NUM;
//    INPUT >> PAT_NUM;*/
//    for(int i=1; i <= 7; i++){
//        //INPUT << "//" << i << '\n';
//        
//        int mode;
//        mode = 3;
//        int w[6], vgs[6], vds[6];
//        for(int j=1; j <= 7; j++){
//            //gen_input(w, vgs, vds); 
//            INPUT << mode << '\n';
//            
//            for(int k=0; k < 6; k++){
//                w[k] = 7;
//                vgs[k] = i;
//                vds[k] = j;
//                INPUT << 7 << " " << vgs[k] << " " << vds[k] << '\n';
//            }
//            INPUT << '\n';
//            
//            int ans = gen_output(w, vgs, vds, mode);
//            OUTPUT << ans << '\n';
//        }
//    }
//
//}


/*
void gen_input(int* w, int* vgs, int* vds){
    for(int i=0; i < 6; i++){
        w[i] = rand()%7 + 1;
        vgs[i] = rand()%7 + 1;
        vds[i] = rand()%7 + 1;
    }
}*/



int gen_output(int* w, int* vgs, int* vds, int mode){
    int id[6], gm[6];
    int ans;
    for(int i=0; i<6; i++){
        if(vgs[i]-1 > vds[i]){
            id[i] = (w[i] * vds[i] * (2 * vgs[i]-2 - vds[i]) )/3;
            gm[i] = 2 * w[i] * vds[i] / 3;
        }else{
            id[i] = w[i] * ((vgs[i] - 1)* (vgs[i] - 1)) /3;
            gm[i] = 2 * w[i] * (vgs[i]-1)/3;
        }
    }
    if(mode == 1 || mode == 3){
        sort(id, id+6);
        /*for(int i=0; i < 6; i++){
            cout << id[i] << " ";
        }
        cout << '\n';*/
    }else{
        sort(gm, gm+6);
        /*for(int i=0; i < 6; i++){
            cout << gm[i] << " ";
        }
        cout << '\n';*/
    }
    
    if(mode == 0){
        ans = (gm[0] + gm[1] + gm[2])/3;
    }else if(mode == 1){
        ans = (3 * id[2] + 4 * id[1] + 5 * id[0])/12;
    }else if(mode == 2){
        ans = (gm[3] + gm[4] + gm[5])/3;
    }else{
        ans = (3 * id[5] + 4 * id[4] + 5 * id[3])/12;
    }
    return ans;
}