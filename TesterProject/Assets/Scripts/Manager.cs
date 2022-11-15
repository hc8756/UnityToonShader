using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;
public class Manager : MonoBehaviour
{
    public static Manager instance;
    public Material[] myMaterials = new Material[3];
    private enum States { None=1, Color=2, Normal=3, Roughness=4, AddLight=5};
    private States currentState;
    private string UIstring;
    public TMP_Text UItext;
    // Start is called before the first frame update
    private void Awake()
    {
        if (instance != null)
        {
            Debug.LogWarning("Found more than one manager in scene");
        }
        instance = this;
    }

    private void Start()
    {
        currentState = States.None;
        UpdateState();
    }

    public void NextEnum(){
        if (currentState == States.None)
            currentState = States.Color;
        else if (currentState == States.Color)
            currentState = States.Normal;
        else if (currentState == States.Normal)
            currentState = States.Roughness;
        else if (currentState == States.Roughness)
            currentState = States.AddLight;
        UpdateState();
    }

    public void PrevEnum() {

        if (currentState == States.AddLight)
            currentState = States.Roughness;
        else if (currentState == States.Roughness)
            currentState = States.Normal;
        else if (currentState == States.Normal)
            currentState = States.Color;        
        else if (currentState == States.Color)
            currentState = States.None;
        UpdateState();
    }

    private void UpdateState() { 
        UIstring = (int)currentState + "/5";
        UItext.text = UIstring;
        foreach (Material m in myMaterials)
        {
            m.SetFloat("_MyState", (float)currentState);
        }
    }
}
