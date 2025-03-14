import * as wxopensdk from '@tencent/wechat_open_sdk';
import { application, common } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { WXApi, WXEventHandler } from './WXApi';
import { APP_ID, APP_SECRET } from '../constants/WXKey';
import { ErrCode, PayResp, SendAuthResp } from '@tencent/wechat_open_sdk';
import { ToastUtil } from '@pura/harmony-utils';
import { image } from '@kit.ImageKit';
import { JSON } from '@kit.ArkTS';


export interface WeChatPayParam {
  appId: string, // 填写下单时传入的【公众账号ID】appid。
  partnerId: string // 填写下单时传入的【商户号】mchid。
  prepayId: string // 预支付交易会话标识。APP下单接口返回的prepay_id，该值有效期为2小时，超过有效期需要重新请求APP下单接口以获取新的prepay_id。
  nonceStr: string //  随机字符串，不长于32位。该值建议使用随机数算法生成。
  timeStamp: string //  注意：常见时间戳为秒级或毫秒级，该处必需传秒级时间戳。
  sign: string // 签名，使用字段appId、timeStamp、nonceStr、prepayId以及商户API证书私钥生成的RSA签名值
}

let context = getContext() as common.UIAbilityContext;

export class WeChatTool {
  // 微信分享场景 默认会话
  static scene = wxopensdk.SendMessageToWXReq.WXSceneSession

  static registerShareResult() {
    let tempResp = (resp: wxopensdk.BaseResp) => {
      if (resp.errCode == ErrCode.ERR_OK) {
        ToastUtil.showToast('分享成功')
      } else {
        ToastUtil.showToast('分享失败')
      }
      WXEventHandler.unregisterOnWXRespCallback(tempResp)
    }
    WXEventHandler.registerOnWXRespCallback(tempResp)
  }

  // 微信分享文字
  static async wechatTextShare(text: string) {
    WeChatTool.registerShareResult()
    let textObject = new wxopensdk.WXTextObject
    textObject.text = text

    let mediaMessage = new wxopensdk.WXMediaMessage()
    mediaMessage.mediaObject = textObject

    let req = new wxopensdk.SendMessageToWXReq()
    req.scene = WeChatTool.scene // 分享场景为绘会话
    req.message = mediaMessage

    let finished = await WXApi.sendReq(context, req)
    console.log("send request finished: ", finished)
  }

  // 微信分享网络图片
  static async wechatImageShare(url: string) {
    if (!url) {
      return
    }
    WeChatTool.registerShareResult()
    let imageData = await downloadImageWithUrl(url)
    WeChatTool.wechatImageBufferShare(imageData)
  }

  // 微信分享图片(ArrayBuffer)
  static async wechatImageBufferShare(imageData: ArrayBuffer) {
    WeChatTool.registerShareResult()
    let file: fileIo.File | undefined;
    let filePath = context.filesDir + `/original-${Date.now()}.jpg`;
    file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
    fileIo.writeSync(file.fd, imageData);
    fileIo.closeSync(file);

    let imageObject = new wxopensdk.WXImageObject
    imageObject.uri = fileUri.getUriFromPath(filePath);

    let mediaMessage = new wxopensdk.WXMediaMessage()
    mediaMessage.mediaObject = imageObject

    let req = new wxopensdk.SendMessageToWXReq()
    req.scene = WeChatTool.scene
    req.message = mediaMessage

    WXApi.sendReq(context, req)
  }

  // 微信分享图片(base64)
  static async wechatImageBase64StringShare(base64String: string) {
    WeChatTool.registerShareResult()
    let imageObject = new wxopensdk.WXImageObject
    imageObject.imageData = base64String;

    let mediaMessage = new wxopensdk.WXMediaMessage()
    mediaMessage.mediaObject = imageObject

    let req = new wxopensdk.SendMessageToWXReq()
    req.scene = WeChatTool.scene
    req.message = mediaMessage

    WXApi.sendReq(context, req)
  }

  // 网页分享
  static async wechatWebShare(webUrl: string, title: string = '英语趣配音', desc? :string, thumb?: string ) {
    WeChatTool.registerShareResult()
    let webpageObject = new wxopensdk.WXWebpageObject()
    webpageObject.webpageUrl = webUrl

    let mediaMessage = new wxopensdk.WXMediaMessage()
    mediaMessage.mediaObject = webpageObject
    mediaMessage.title = title
    mediaMessage.description = desc

    let thumbData = await context.resourceManager.getMediaContent($r("app.media.ic_default_share"))
    if (thumb) {
      let data = await downloadImageWithUrl(thumb)
      thumbData = new Uint8Array(data)
    }
    mediaMessage.thumbData = thumbData

    let req = new wxopensdk.SendMessageToWXReq()
    req.scene = WeChatTool.scene
    req.message = mediaMessage

    WXApi.sendReq(context, req)
  }

  // 小程序分享
  static async wechatMiniProgramShare(webUrl: string, title: string = '英语趣配音', desc? :string, path?: string, thumb?: string, mini_id?: string ) {
    WeChatTool.registerShareResult()
    let miniProgramObject = new wxopensdk.WXMiniProgramObject()
    miniProgramObject.userName = mini_id ?? "gh_4105318d72d2"
    miniProgramObject.path = path

    let mediaMessage = new wxopensdk.WXMediaMessage()
    mediaMessage.mediaObject = miniProgramObject
    mediaMessage.title = title
    mediaMessage.description = desc

    let thumbData = await context.resourceManager.getMediaContent($r("app.media.ic_default_share"))
    if (thumb) {
      let data = await downloadImageWithUrl(thumb)
      thumbData = new Uint8Array(data)
    }
    mediaMessage.thumbData = thumbData

    const req = new wxopensdk.SendMessageToWXReq()
    req.scene = wxopensdk.SendMessageToWXReq.WXSceneSession
    req.message = mediaMessage

    WXApi.sendReq(context, req)
  }

  // 拉起微信小程序
  static async startMiniProgram(mini_id?: string ,path?: string) {
    let launchMiniProgramReq = new wxopensdk.LaunchMiniProgramReq;
    launchMiniProgramReq.userName = mini_id ?? 'gh_4105318d72d2';  //拉起的小程序的原始id
    launchMiniProgramReq.path = path;    //拉起小程序页面的可带参路径，不填默认拉起小程序首页，对于小游戏，可以只传入 query 部分，来实现传参效果，如：传入 "?foo=bar"。
    WXApi.sendReq(context, launchMiniProgramReq)
  }

  // 微信支付
  static async wechatPay(param: WeChatPayParam, callback: (payResp: PayResp) => void) {
    let tempResp = (resp: wxopensdk.BaseResp) => {
      callback(resp)
      WXEventHandler.unregisterOnWXRespCallback(tempResp)
    }
    WXEventHandler.registerOnWXRespCallback(tempResp)
    let req = new wxopensdk.PayReq
    req.appId = param.appId
    req.partnerId = param.partnerId
    req.prepayId = param.prepayId
    req.packageValue = 'Sign=WXPay'
    req.nonceStr = param.nonceStr
    req.timeStamp = param.timeStamp.toString()
    req.sign = param.sign
    WXApi.sendReq(context, req)
  }

  // 微信授权 1.发起授权
  static async weChatAuth(complete: (data: Record<string, string>) => void) {
    let tempResp = (resp: wxopensdk.BaseResp) => {
      if (resp.errCode != ErrCode.ERR_OK) {
        WXEventHandler.unregisterOnWXRespCallback(tempResp)
        return
      }
      let authResp = resp as SendAuthResp
      WeChatTool.getAccessToken(authResp.code ?? '0', (wxData) => {
        if (wxData) {
          complete(wxData)
        }
        WXEventHandler.unregisterOnWXRespCallback(tempResp)
      })
    }
    WXEventHandler.registerOnWXRespCallback(tempResp)
    let req = new wxopensdk.SendAuthReq;
    req.scope = "snsapi_userinfo";
    WXApi.sendReq(context, req)
  }

  // 微信授权 2.获取accessToken\openid等信息
  static async getAccessToken(code: string, result: (data: Record<string, string> | undefined) => void) {
    let url = 'https://api.weixin.qq.com/sns/oauth2/access_token?'
    let httpRequest = http.createHttp();
    let promise =
      httpRequest.request(`${url}appid=${APP_ID}&secret=${APP_SECRET}&code=${code}&grant_type=authorization_code`);
    promise.then((data: http.HttpResponse) => {
      console.info('Result:' + JSON.stringify(data));
      let wxData = JSON.parse(data.result as string) as Record<string, string>
      WeChatTool.getWeChatUserInfo(wxData, (data)=> {
        if (data) {
          wxData['nickname'] = data['nickname']
          wxData['headimgurl'] = data['headimgurl']
        }
        result(wxData)
      })
      httpRequest.destroy();
    }).catch((err: Error) => {
      console.info('error:' + JSON.stringify(err));
      result(undefined)
      httpRequest.destroy();
    });
  }

  // 微信授权 3.获取用户昵称、头像等信息
  static async getWeChatUserInfo(data: Record<string, string>,
    result: (data: Record<string, string> | undefined) => void) {
    let url = 'https://api.weixin.qq.com/sns/userinfo?';
    let token: string = data['access_token'];
    let openid: string = data['openid'];
    let httpRequest = http.createHttp();
    let promise = httpRequest.request(`${url}access_token=${token}&openid=${openid}`);
    promise.then((data: http.HttpResponse) => {
      console.info('Result:' + JSON.stringify(data));
      let userData = JSON.parse(data.result as string) as Record<string, string>
      result(userData)
      httpRequest.destroy();
    }).catch((err: Error) => {
      console.info('error:' + JSON.stringify(err));
      result(undefined)
      httpRequest.destroy();
    });
  }
}

async function downloadImageWithUrl(url: string) : Promise<ArrayBuffer> {
   let data = await http.createHttp().request(url)
   return data.result as ArrayBuffer
}