const onFormSubmit = async (e) => {
  updateProgress(0, 0, 0, 0);
  setLoading(false);

  e.preventDefault();
  enableSubmitButton(true);
  const usernames = (document.getElementById("User_name").value || "")
    .trim()
    .split("\n")
    .reduce((arr, line) => {
      line = (line || "").trim();
      if (line) arr.push(line);
      return arr;
    }, []);

  if (usernames.length <= 0) return alert("Username is empty !");

  const domain = document.getElementById("User_domain").value;
  const plainPassword = document.getElementById("User_plainPassword").value;
  const admin = document.getElementById("User_admin").value;
  const domainAdmin = document.getElementById("User_domainAdmin").value;
  const enabled = document.getElementById("User_enabled").value;
  const sendOnly = document.getElementById("User_sendOnly").value;
  const quota = document.getElementById("User_quota").value;

  enableSubmitButton(false);
  setLoading(true);
  let successCount = 0;
  let errorCount = 0;
  let progressIndex = 0;
  for (const username of usernames) {
    progressIndex++;
    updateProgress(usernames.length, progressIndex, successCount, errorCount);

    const fomData = new URLSearchParams();

    fomData.set("ea[newForm][btn]", "saveAndReturn");
    fomData.set("User[domain]", domain);
    fomData.set("User[name]", username);
    fomData.set("User[plainPassword]", plainPassword);
    fomData.set("User[enabled]", enabled);
    fomData.set("User[quota]", quota);
    fomData.set("User[_token]", "csrf-token");

    // console.log({ domain, username, plainPassword, enabled, quota });

    try {
      const response = await fetch(location.href, {
        method: "POST",
        body: fomData.toString(),
        headers: {
          "content-type": "application/x-www-form-urlencoded",
        },
        redirect: "manual",
      });

      if (response.type === "opaqueredirect") {
        successCount++;
      } else {
        errorCount++;
      }
    } catch (error) {
      console.error(error);
    } finally {
      updateProgress(usernames.length, progressIndex, successCount, errorCount);
    }
  }
  enableSubmitButton(true);
  setLoading(false);
};

function updateProgress(total, index, success, error) {
  document.getElementById(`progress-box`).innerHTML = `
        <span>Progress: <b>${index}/${total}</b></span>|
        <span>Success: <span style="color:green"><b>${success}</b></span></span>|
        <span>Error: <span style="color:red"><b>${error}</b></span></span>
        `;

  document.getElementById("progressbar").max = total;
  document.getElementById("progressbar").value = index;
}

function enableSubmitButton(isEnable = false) {
  try {
    if (isEnable) {
      document.querySelectorAll(`[type=submit]`).forEach((el) => el.removeAttribute("disabled"));
    } else {
      document.querySelectorAll(`[type=submit]`).forEach((el) => el.setAttribute("disabled", "disabled"));
    }
  } catch (error) {}
}

function setLoading(isLoading = false) {
  const form = document.getElementById("new-User-form");
  const elements = form.elements;
  for (let i = 0, len = elements.length; i < len; ++i) {
    elements[i].readOnly = isLoading;
  }

  document.querySelector(`button.action-saveAndReturn`).innerHTML = isLoading
    ? `<i style="animation: rotation 1s linear infinite" class="fa-solid fa-spinner"></i>`
    : "Create";

  document.querySelector(`button.action-saveAndReturn`).style["width"] = "58px";
  document.querySelector(`button.action-saveAndReturn`).style["height"] = "29px";
}

document.addEventListener("DOMContentLoaded", () => {
  const oldHeadContent = document.querySelector(`.content-header-title`).innerHTML;
  document.querySelector(`.content-header-title`).innerHTML = `
  ${oldHeadContent}
  <div style="display:flex;gap:8px" id="progress-box"></div>
  <progress id="progressbar" type="range" readonly style="width:100%"/>`;
  updateProgress(0, 0, 0, 0);

  const form = document.getElementById("new-User-form");
  form.addEventListener("submit", onFormSubmit);

  const style = document.createElement("style");
  style.innerHTML = `
  @keyframes rotation {0% {transform: rotate(0deg);}100% {transform: rotate(360deg);}} 

    progress {
        -webkit-appearance: none;
    }

    ::-webkit-progress-bar {
        background-color: #ccc;
        height:4px;
    }

    ::-webkit-progress-value {
        background-color: #2575ec;
    }
  
  `;

  document.head.appendChild(style);
});
